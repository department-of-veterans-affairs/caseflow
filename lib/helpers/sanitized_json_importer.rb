# frozen_string_literal: true

require "helpers/sanitized_json_difference.rb"

# Given JSON, this class parses it as records and creates those records in the database.
# 
# Approach:
# - Import records using an id_offset (which is added to the value of all the *_id fields)
#   - to avoid conflict with existing records
#   - to easily identify imported records
#   - See `adjust_ids_by_offset` and `offset_id_table_fields`.
# - For certain record types (e.g., Organization, User, Person, Veteran), reuse them if the
#   record already exists. See `nonduplicate_types`.
#   - This means when an existing record is found, it is used instead of the id_offset,
#     which means the importer needs to track the `id_mapping` from original id (in the JSON)
#     to the id of the existing record so that association records like OrganizationsUser
#     (which only refer to `user_id` and `organization_id`) can be mapped properly.
#
# The major logic is in `import_record`.
##

class SanitizedJsonImporter
  prepend SanitizedJsonDifference

  attr_accessor :records_hash # this is modified during importing
  attr_accessor :metadata

  # output
  attr_accessor :imported_records
  attr_accessor :reused_records

  def self.from_file(filename, **kwargs)
    new(File.read(filename), **kwargs)
  end

  # def self.attributes_with_unique_index(clazz)
  #   unique_indices = ActiveRecord::Base.connection.indexes(clazz.table_name).select(&:unique)
  #   unique_indices.map(&:columns).flatten.uniq
  # end

  def initialize(file_contents, configuration: SanitizedJsonConfiguration.new, verbosity: 8)
    @configuration = configuration
    @id_offset = configuration.id_offset
    @records_hash = JSON.parse(file_contents)
    @metadata = @records_hash.delete("metadata")
    @imported_records = {}
    @reused_records = {}

    @verbosity = verbosity # for debugging; higher is more verbose
  end

  def import
    ActiveRecord::Base.transaction do
      @configuration.first_types_to_import.each do |clazz|
        import_array_of(clazz)
      end

      @records_hash.each do |key, obj_hash_array|
        import_array_of(key.classify.constantize, key, obj_hash_array)
      end
    end
    imported_records
  end

  def id_mapping
    # Keep track of id mappings for these record types to reassociate to newly imported records
    @id_mapping ||= @configuration.id_mapping_types.map { |clazz| [clazz.name, {}] }.to_h
  end

  private

  def import_array_of(clazz, key = clazz.table_name, obj_hash_array = @records_hash.fetch(key, []))
    new_records = obj_hash_array.map do |obj_hash|
      fail "No JSON data for records_hash key: #{key}" unless obj_hash

      import_record(key, clazz, obj_hash)
    end
    imported_records[key] = new_records
    @records_hash.delete(key)
  end

  def import_record(key, clazz, obj_hash)
    # Record original id in case it changes in the following lines
    orig_id = obj_hash["id"]

    # Don't import if certain types of records already exists
    if @configuration.nonduplicate_types.include?(clazz) && (existing_record = find_existing_record(clazz, obj_hash))
      puts "  = Using existing #{clazz} instead of importing #{obj_hash['type']} #{obj_hash['id']}"
      reused_records[key] ||= []
      reused_records[key] << existing_record
      id_mapping_key = clazz.table_name.classify
      unless id_mapping[id_mapping_key]
        puts "ERROR: add #{id_mapping_key} to @configuration.id_mapping_types"
        id_mapping[id_mapping_key] = {}
      end
      # Track it for use by association records like OrganizationsUser in @configuration.find_existing_record
      id_mapping[id_mapping_key][orig_id] = existing_record.id
      return
    end

    obj_description = "original: #{obj_hash['type']} " \
                      "#{obj_hash.select { |obj_key, _v| obj_key.include?('_id') }}"

    if @configuration.nonduplicate_types.include?(clazz)
      singleton = @configuration.create_singleton(clazz, obj_hash, obj_description: obj_description)
      if singleton
        fail "Consider: Nonduplicate_type #{clazz.name} should be an entry in @configuration.id_mapping_types" unless id_mapping[clazz.table_name.classify]
        id_mapping[clazz.table_name.classify] ||= {}
        id_mapping[clazz.table_name.classify][orig_id] = obj_hash["id"]
        return singleton
      end
    end

    adjust_ids_by_offset(clazz, obj_hash)
    reassociate_with_imported_records(clazz, obj_hash)

    @configuration.before_creation_hook(clazz, obj_hash, obj_description: obj_description, importer: self)
    puts "  + Creating #{clazz} #{obj_hash['id']} \n\t#{obj_description}"
    create_new_record(orig_id, clazz, obj_hash)
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
      .transform_values { |class_to_fieldnames_hash| class_to_fieldnames_hash.transform_keys(&:table_name) }.freeze
  end

  # :reek:FeatureEnvy
  def reassociate_with_imported_records(clazz, obj_hash)
    # Handle polymorphic associations (where the association class is stored in the *'_type' field)
    puts "  | Reassociate polymorphic associations for #{clazz.name}" if @verbosity > 5
    reassociate_type_table_fields[clazz.table_name]&.each do |field_name|
      fail "!!! Expecting field_name to end with '_id' but got: #{field_name}" unless field_name.ends_with?("_id")

      association_type = obj_hash[field_name.sub(/_id$/, "_type")]
      record_id_mapping = id_mapping[association_type]
      reassociate(obj_hash, field_name, record_id_mapping, association_type: association_type)
    end

    # Handle associations where the association class is not stored (it is implied)
    # For each type in reassociate_table_fields_hash, iterate through each field_name in reassociate_table_fields
    # and reassociate the field to the imported record
    reassociate_table_fields_hash.each do |association_type, reassociate_table_fields|
      puts "  | Reassociate #{clazz.name} fields for #{association_type} associations" if @verbosity > 5
      record_id_mapping = id_mapping[association_type]
      # binding.pry if clazz = OrganizationsUser
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
    puts "    > reassociated #{id_field}: #{association_type} #{orig_record_id}->#{obj_hash[id_field]}"
    [orig_record_id, obj_hash[id_field]]
  end

  def find_existing_record(clazz, obj_hash)
    existing_record = @configuration.find_existing_record(clazz, obj_hash, importer: self)
    return existing_record if existing_record

    find_record_by_unique_index(clazz, obj_hash)

    # binding.pry if OrganizationsUser == clazz

    # existing_record = clazz.find_by_id(obj_hash["id"])
    # unless existing_record
    #   # Try searching for previously imported record
    #   # TODO: generalize; see org_already_exists
    #   # TODO: for association records like OrganizationsUser, need to check with user/organization_id fields updated
    #   existing_record = clazz.find_by_id(obj_hash["id"] + @id_offset)
    #   obj_hash["id"] += @id_offset if existing_record
    # end

    # return existing_record if existing_record && same_unique_attributes?(existing_record, obj_hash)

    # if existing_record
    #   obj_hash_clone = obj_hash
    #   # adjust_ids_by_offset(clazz, obj_hash_clone)
    #   reassociate_with_imported_records(clazz, obj_hash_clone)
    #   # existing_record ||= clazz.find_by_id(obj_hash_clone["id"] + @id_offset)
    #   # binding.pry if OrganizationsUser == clazz
    #   existing_record if existing_record && same_unique_attributes?(existing_record, obj_hash_clone)
    # end
  end

  # Try to find record using unique indices on the corresponding table
  def find_record_by_unique_index(clazz, obj_hash)
    unique_indices = ActiveRecord::Base.connection.indexes(clazz.table_name).select(&:unique)
    found_records = unique_indices.map(&:columns).map { |fieldnames|
      next nil if fieldnames.is_a?(String) # occurs for custom indices like for User
      next nil unless (fieldnames - clazz.column_names).blank?

      uniq_attributes = fieldnames.map { |fieldname| [fieldname, obj_hash[fieldname]]}.to_h
      clazz.find_by(uniq_attributes)
    }.compact

    return nil if found_records.blank?

    # puts "Found #{clazz.name}: #{found_records}"
    return found_records.first if found_records.size == 1

    fail "Found multiple records for #{clazz.name}: #{found_records}"
  end

  # For records where we want to reuse the existing record
  # :reek:FeatureEnvy
  # def same_unique_attributes?(existing_record, obj_hash)
  #   is_same = @configuration.same_unique_attributes?(existing_record, obj_hash, importer: self)
  #   return is_same unless is_same.nil?

  #   # binding.pry if OrganizationsUser == existing_record.class
  #   unique_attributes_per_tablename[existing_record.class.table_name]&.all? do |fieldname|
  #     existing_record.send(fieldname) == obj_hash[fieldname]
  #   end
  # end

  # def unique_attributes_per_tablename
  #   @unique_attributes_per_tablename ||= @configuration.id_mapping_types.map do |clazz|
  #     [clazz.table_name, self.class.attributes_with_unique_index(clazz)]
  #   end.to_h.freeze
  # end
end
