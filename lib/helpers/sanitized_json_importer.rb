# frozen_string_literal: true

require "helpers/sanitized_json_difference.rb"

# Given JSON, this class parses it as records and creates those records in the database.
#
# Approach:
# - Import records using an `id_offset` (which is added to the value of all the *_id fields)
#   - to avoid conflict with existing records
#   - to easily identify imported records
#   - See `adjust_ids_by_offset` and `offset_id_table_fields`.
# - For certain record types (e.g., Organization, User, Person, Veteran), reuse them if the
#   record already exists in the database. See `reuse_record_types`.
#   - This means when an existing record is found, it is used instead of the `id_offset`,
#     which means the importer needs to track the `id_mapping` from original id (in the JSON)
#     to the id of the existing record so that association records like OrganizationsUser
#     (which only refer to `user_id` and `organization_id`) can be mapped properly.
#
# To summarize, fields that reference other records must be updated,
# either by an `id_offset` or using the `id_mapping`.
#
# The major logic is in `import_record`.
##

class SanitizedJsonImporter
  prepend SanitizedJsonDifference

  # parsed from JSON input
  attr_accessor :metadata

  # Hash parsed from JSON input, whose id fields are modified during importing
  # key = ActiveRecord class's table_name; value = array of JSON of ActiveRecords
  attr_accessor :records_hash

  # Hash of records imported into the database
  # key = ActiveRecord class's table_name; value = ActiveRecords in the database
  attr_accessor :imported_records

  # Existing ActiveRecords that are not imported because they already exist in the database
  attr_accessor :reused_records

  def self.from_file(filename, **kwargs)
    new(File.read(filename), **kwargs)
  end

  def initialize(file_contents,
                 configuration: SanitizedJsonConfiguration.new,
                 verbosity: ENV["SJ_VERBOSITY"] ? ENV["SJ_VERBOSITY"].to_i : 2)
    @configuration = configuration
    @id_offset = configuration.id_offset
    @records_hash = JSON.parse(file_contents)
    @metadata = @records_hash.delete("metadata")
    @imported_records = {}
    @reused_records = {}

    # unique indices for the table associated with a class
    @unique_indices_per_class = {}

    @verbosity = verbosity # higher is more verbose
  end

  def import
    ActiveRecord::Base.transaction do
      @configuration.first_types_to_import.each do |clazz|
        import_array_of(clazz)
      end

      # for the remaining classes from the JSON, import the records
      @records_hash.each do |key, obj_hash_array|
        import_array_of(key.classify.constantize, key, obj_hash_array)
      end
    end
    if @verbosity > 0
      puts "Imported #{imported_records.values.map(&:count).sum} records; "\
           "reused #{reused_records.values.map(&:count).sum} existing records"
    end
    imported_records
  end

  def id_mapping
    # Keep track of id mappings for these record types to reassociate to newly imported records
    @id_mapping ||= @configuration.id_mapping_types.map { |clazz| [clazz.name, {}] }.to_h
  end

  def update_association_fields(clazz, obj_hash)
    adjust_ids_by_offset(clazz, obj_hash)
    reassociate_with_imported_records(clazz, obj_hash)
    obj_hash
  end

  private

  def unique_indices_per_class(clazz)
    @unique_indices_per_class.fetch(clazz) do
      @unique_indices_per_class[clazz] = ActiveRecord::Base.connection.indexes(clazz.table_name).select(&:unique)
    end
  end

  def import_array_of(clazz, key = clazz.table_name, obj_hash_array = @records_hash.fetch(key, []))
    puts "Importing #{obj_hash_array.count} #{clazz} records" if @verbosity > 1
    imported_records[key] = obj_hash_array.map do |obj_hash|
      next puts "WARNING: No JSON data for records_hash key: #{key}" unless obj_hash

      import_record(key, clazz, obj_hash)
    end
    @records_hash.delete(key)
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def import_record(key, clazz, obj_hash)
    # Record original id in case it changes in the following lines
    orig_id = obj_hash["id"]
    puts " * Starting import of #{clazz} #{obj_hash['type']} #{obj_hash['id']}" if @verbosity > 5

    # Step 1: Don't import if certain types of records already exists; register them for later use
    if @configuration.reuse_record_types.include?(clazz) && (existing_record = find_existing_record(clazz, obj_hash))
      puts "  = Using existing #{clazz} instead of importing #{obj_hash['type']} #{obj_hash['id']}" if @verbosity > 2
      reused_records[key] ||= []
      reused_records[key] << existing_record
      # Track it for use by association records like OrganizationsUser in @configuration.find_existing_record
      add_to_id_mapping(clazz, orig_id, existing_record.id)
      return
    end

    # Step 2: Create singleton records if appropriate
    obj_description = "original: #{obj_hash['type']} " \
                      "#{obj_hash.select { |obj_key, _v| obj_key.include?('_id') }}"
    if @configuration.reuse_record_types.include?(clazz)
      singleton = @configuration.create_singleton(clazz, obj_hash, obj_description: obj_description)
      if singleton
        add_to_id_mapping(clazz, orig_id, obj_hash["id"])
        return singleton
      end
    end

    # Step 3: Update *_id fields and associations
    update_association_fields(clazz, obj_hash)

    # Step 4: Create record in the database
    @configuration.before_creation_hook(clazz, obj_hash, obj_description: obj_description, importer: self)
    puts "  + Creating #{clazz} #{obj_hash['id']} \n\t#{obj_description}" if @verbosity > 2
    create_new_record(orig_id, clazz, obj_hash)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def add_to_id_mapping(clazz, orig_id, new_id)
    id_mapping_key = clazz.table_name.classify
    unless id_mapping[id_mapping_key]
      # puts "Consider: adding #{id_mapping_key} to @configuration.id_mapping_types"
      id_mapping[id_mapping_key] = {}
    end
    id_mapping[id_mapping_key][orig_id] = new_id
  end

  # :reek:FeatureEnvy
  def adjust_ids_by_offset(clazz, obj_hash)
    obj_hash["id"] += @id_offset

    # Use table_name to handle subclasses/STI: e.g., a HearingTask record maps to table "tasks"
    offset_id_table_fields[clazz.table_name]&.each do |field_name|
      if obj_hash[field_name].is_a?(Array)
        obj_hash[field_name] = obj_hash[field_name].map { |id| id + @id_offset }
      elsif obj_hash[field_name]
        obj_hash[field_name] += @id_offset
      end
    end
  end

  def offset_id_table_fields
    @offset_id_table_fields ||= @configuration.offset_id_fields.transform_keys(&:table_name).freeze
  end

  # Using this approach: https://mattpruitt.com/articles/skip-callbacks/
  # Other resources:
  # * https://api.rubyonrails.org/classes/ActiveSupport/Callbacks.html
  # * https://www.allerin.com/blog/save-an-object-skipping-callbacks-in-rails-3-application
  # * http://ashleyangell.com/2019/06/skipping-an-activerecord-callback-programatically/
  module SkipCallbacks
    def run_callbacks(kind, *args, &block)
      if [:save, :create].include?(kind)
        # puts "(Skipping callbacks for #{kind}: #{args})"
        nil
      else
        super
      end
      yield(*args) if block_given?
    end
  end

  # :reek:FeatureEnvy
  def create_new_record(orig_id, clazz, obj_hash)
    # Record new id for certain record types
    id_mapping[clazz.table_name.classify][orig_id] = obj_hash["id"] if id_mapping[clazz.table_name.classify]

    if @configuration.types_that_skip_validation_and_callbacks.include?(clazz)
      # Create the record without validation or callbacks
      new_record = clazz.new(obj_hash)
      new_record.extend(SkipCallbacks) # monkeypatch only this in-memory instance of the record
      new_record.save(validate: false)
      new_record
    else
      clazz.create!(obj_hash)
    end
  end

  def reassociate_type_table_fields
    @reassociate_type_table_fields ||= @configuration.reassociate_fields[:type].transform_keys(&:table_name).freeze
  end

  def reassociate_table_fields_hash
    @reassociate_table_fields_hash ||= @configuration.reassociate_fields
      .select { |type_string, _| type_string.is_a?(String) }
      .transform_values { |class_to_fieldnames_hash| class_to_fieldnames_hash.transform_keys(&:table_name) }
      .freeze
  end

  # :reek:FeatureEnvy
  def reassociate_with_imported_records(clazz, obj_hash)
    # Handle polymorphic associations (where the association class is stored in the *'_type' field)
    puts "  | Reassociate polymorphic associations for #{clazz.name}" if @verbosity > 4
    reassociate_type_table_fields[clazz.table_name]&.each do |field_name|
      fail "!!! Expecting field_name to end with '_id' but got: #{field_name}" unless field_name.ends_with?("_id")

      association_type = obj_hash[field_name.sub(/_id$/, "_type")]
      reassociate(obj_hash, field_name, id_mapping[association_type], association_type: association_type)
    end

    # Handle associations where the association class is not stored (it is implied)
    # For each type in reassociate_table_fields_hash, iterate through each field_name in reassociate_table_fields
    # and reassociate the field to the imported record
    reassociate_table_fields_hash.each do |association_type, reassociate_table_fields|
      puts "  | Reassociate #{clazz.name} fields for #{association_type} associations" if @verbosity > 4
      record_id_mapping = id_mapping[association_type]
      reassociate_table_fields[clazz.table_name]&.each do |field_name|
        reassociate(obj_hash, field_name, record_id_mapping, association_type: association_type)
      end
    end
  end

  # :reek:FeatureEnvy
  # :reek:LongParameterList
  def reassociate(obj_hash, id_field, record_id_mapping, association_type: nil)
    orig_record_id = obj_hash[id_field]
    return unless orig_record_id

    obj_hash[id_field] = record_id_mapping[orig_record_id] if record_id_mapping[orig_record_id]
    if @verbosity > 3
      puts "    > reassociated #{id_field}: #{association_type} #{orig_record_id}->#{obj_hash[id_field]}"
    end
    [orig_record_id, obj_hash[id_field]]
  end

  # Try to find record using unique indices on the corresponding table
  # :reek:FeatureEnvy
  def find_record_by_unique_index(clazz, obj_hash)
    found_records = unique_indices_per_class(clazz).map(&:columns).map do |fieldnames|
      next nil if fieldnames.is_a?(String) # occurs for custom indices like for User
      next nil unless (fieldnames - clazz.column_names).blank? # in case a fieldname is not a column

      uniq_attributes = fieldnames.map { |fieldname| [fieldname, obj_hash[fieldname]] }.to_h
      clazz.find_by(uniq_attributes)
    end.compact

    return nil if found_records.blank?

    puts "Found #{clazz.name} record(s) by unique index: #{found_records}" if @verbosity > 5
    return found_records.first if found_records.size == 1

    fail "Found multiple records for #{clazz.name}: #{found_records}"
  end

  def find_existing_record(clazz, obj_hash)
    existing_record = @configuration.find_existing_record(clazz, obj_hash, importer: self)
    return existing_record if existing_record

    existing_record = find_record_by_unique_index(clazz, obj_hash)
    return existing_record if existing_record

    # Try updating the *_id fields in a clone of obj_hash by reassociating with the imported records,
    # then search for an existing record.
    # Example: OrganizationsUser requires the (user_id,organization_id) combination to be unique,
    # and User and Organization are mapped to possibly different id's (not simply an id_offset)
    obj_hash_clone = update_association_fields(clazz, obj_hash.clone)
    existing_record = find_record_by_unique_index(clazz, obj_hash_clone)
    if existing_record
      # Since existing_record was found, update obj_hash
      update_association_fields(clazz, obj_hash)
      existing_record
    end
  end
end
