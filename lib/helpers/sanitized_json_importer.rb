# frozen_string_literal: true

require "helpers/sanitized_json_difference.rb"
# require "helpers/sanitized_json_exporter.rb"

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
  attr_accessor :metadata

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
    fail "Importing is not allowed in production!" if Rails.env.production?

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
      @configuration.first_types_to_import.each do |klass|
        import_array_of(klass)
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
    @id_mapping ||= @configuration.id_mapping_types.map { |klass| [klass.name, {}] }.to_h
  end

  def update_association_fields(klass, obj_hash)
    adjust_ids_by_offset(klass, obj_hash)
    reassociate_with_imported_records(klass, obj_hash)
    obj_hash
  end

  private

  def unique_indices_per_class(klass)
    @unique_indices_per_class.fetch(klass) do
      @unique_indices_per_class[klass] = ActiveRecord::Base.connection.indexes(klass.table_name).select(&:unique)
    end

  def import_array_of(klass, key = klass.table_name, obj_hash_array = @records_hash.fetch(key, []))
    puts "Importing #{obj_hash_array.count} #{klass} records" if @verbosity > 1
    imported_records[key] = obj_hash_array.map do |obj_hash|
      next puts "WARNING: No JSON data for records_hash key: #{key}" unless obj_hash

      import_record(key, klass, obj_hash)
    end.compact
    @records_hash.delete(key)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def import_record(key, klass, obj_hash)
    # Record original id in case it changes in the following lines
    orig_id = obj_hash["id"]
    puts " * Starting import of #{klass} #{obj_hash['type']} #{obj_hash['id']}" if @verbosity > 5

    # Step 1: Don't import if certain types of records already exists; register them for later use
    if @configuration.reuse_record_types.include?(klass) && (existing_record = find_existing_record(klass, obj_hash))
      puts "  = Using existing #{klass} instead of importing #{obj_hash['type']} #{obj_hash['id']}" if @verbosity > 1
      reused_records[key] ||= []
      reused_records[key] << existing_record
      # Track it for use by association records like OrganizationsUser in @configuration.find_existing_record
      add_to_id_mapping(klass, orig_id, existing_record.id)
      return
    end

    # Step 2: Update *_id fields and associations
    update_association_fields(klass, obj_hash)

    # Step 3: Create record in the database
    obj_description = "original: #{obj_hash['type']} " \
                      "#{obj_hash.select { |obj_key, _v| obj_key.include?('_id') }}"
    @configuration.before_creation_hook(klass, obj_hash, obj_description: obj_description, importer: self)
    puts "  + Creating #{klass} #{obj_hash['id']} \n\t#{obj_description}" if @verbosity > 2
    create_new_record(orig_id, klass, obj_hash)
  end

  def add_to_id_mapping(klass, orig_id, new_id)
    id_mapping_key = klass.table_name.classify
    id_mapping[id_mapping_key] ||= {}
    id_mapping[id_mapping_key][orig_id] = new_id
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity

  private

  def mapped_appeal_ids
    @mapped_ids[Appeal.name.underscore]
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity

  def mapped_user_ids
    @mapped_ids[User.name.underscore]
  end

  def mapped_org_ids
    @mapped_ids[Organization.name.underscore]
  end

  OFFSET_ID_TABLE_FIELDS = SanitizedJsonExporter::OFFSET_ID_FIELDS.transform_keys(&:table_name).freeze

  # :reek:FeatureEnvy
  def adjust_ids_by_offset(klass, obj_hash)
    obj_hash["id"] += @id_offset

    # Use table_name to handle subclasses/STI: e.g., a HearingTask record maps to table "tasks"
    offset_id_table_fields[klass.table_name]&.each do |field_name|
      if obj_hash[field_name].is_a?(Array)
        obj_hash[field_name] = obj_hash[field_name].map { |id| id + @id_offset }
      elsif obj_hash[field_name].is_a?(String)
        obj_hash[field_name] = (obj_hash[field_name].to_i + @id_offset).to_s
      elsif obj_hash[field_name]
        obj_hash[field_name] += @id_offset
      end
    end
  end
  # rubocop:enable

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
  def create_new_record(orig_id, klass, obj_hash)
    # Record new id for certain record types
    id_mapping[klass.table_name.classify][orig_id] = obj_hash["id"] if id_mapping[klass.table_name.classify]

    if @configuration.types_that_skip_validation_and_callbacks.include?(klass)
      # Create the record without validation or callbacks
      new_record = klass.new(obj_hash)
      new_record.extend(SkipCallbacks) # monkeypatch only this in-memory instance of the record
      new_record.save(validate: false)
      new_record
    else
      klass.create!(obj_hash)
    end
  end

  REASSOCIATE_TYPE_TABLE_FIELDS = SanitizedJsonExporter::REASSOCIATE_FIELDS[:type].transform_keys(&:table_name).freeze
  REASSOCIATE_TABLE_FIELDS_HASH = SanitizedJsonExporter::REASSOCIATE_FIELDS
    .select { |type_string, _| type_string.is_a?(String) }
    .transform_values { |class_to_fieldnames_hash| class_to_fieldnames_hash.transform_keys(&:table_name) }.freeze

  def user_id_mapping
    @id_mapping[User.name.underscore]
  end

  def reassociate_type_table_fields
    @reassociate_type_table_fields ||= @configuration.reassociate_fields[:type].transform_keys(&:table_name).freeze
  end

  def reassociate(obj_hash, id_field, record_id_mapping)
    obj_hash[id_field] = record_id_mapping[obj_hash[id_field]] if record_id_mapping[obj_hash[id_field]]
  end

  def reassociate_table_fields_hash
    @reassociate_table_fields_hash ||= @configuration.reassociate_fields
      .select { |type_string, _| type_string.is_a?(String) }
      .transform_values { |class_to_fieldnames_hash| class_to_fieldnames_hash.transform_keys(&:table_name) }
      .freeze
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # :reek:FeatureEnvy
  def reassociate_with_imported_records(klass, obj_hash)
    # Handle polymorphic associations (where the association class is stored in the *'_type' field)
    puts "  | Reassociate polymorphic associations for #{klass.name}" if @verbosity > 4
    reassociate_type_table_fields[klass.table_name]&.each do |field_name|
      fail "!!! Expecting field_name to end with '_id' but got: #{field_name}" unless field_name.ends_with?("_id")

      association_type = obj_hash[field_name.sub(/_id$/, "_type")]
      reassociate(obj_hash, field_name, id_mapping[association_type], association_type: association_type)
    end

    # Handle associations where the association class is not stored (it is implied)
    # For each type in reassociate_table_fields_hash, iterate through each field_name in reassociate_table_fields
    # and reassociate the field to the imported record
    reassociate_table_fields_hash.each do |association_type, reassociate_table_fields|
      puts "  | Reassociate #{klass.name} fields for #{association_type} associations" if @verbosity > 4
      record_id_mapping = id_mapping[association_type]
      reassociate_table_fields[klass.table_name]&.each do |field_name|
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
  def find_record_by_unique_index(klass, obj_hash)
    found_records = unique_indices_per_class(klass).map(&:columns).map do |fieldnames|
      next nil if fieldnames.is_a?(String) # occurs for custom indices like for User
      next nil unless (fieldnames - klass.column_names).blank? # in case a fieldname is not a column

      uniq_attributes = fieldnames.map { |fieldname| [fieldname, obj_hash[fieldname]] }.to_h
      klass.find_by(uniq_attributes)
    end.compact

    return nil if found_records.blank?

    puts "Found #{klass.name} record(s) by unique index: #{found_records}" if @verbosity > 5
    return found_records.first if found_records.size == 1

    fail "Found multiple records for #{klass.name}: #{found_records}"
  end

  def find_existing_record(klass, obj_hash)
    @configuration.find_existing_record(klass, obj_hash, importer: self) ||
      find_record_by_unique_index(klass, obj_hash) ||
      find_existing_record_after_reassociating(klass, obj_hash)
  end

  # Try updating the *_id fields in a clone of obj_hash by reassociating with the imported records,
  # then search for an existing record.
  # Example: OrganizationsUser requires the (user_id,organization_id) combination to be unique,
  # and User and Organization are mapped to possibly different id's (not simply an id_offset)
  def find_existing_record_after_reassociating(klass, obj_hash)
    obj_hash_clone = update_association_fields(klass, obj_hash.clone)
    existing_record = find_record_by_unique_index(klass, obj_hash_clone)
    if existing_record
      # Since existing_record was found, update original obj_hash
      update_association_fields(klass, obj_hash)
      existing_record
    end
  end
end
