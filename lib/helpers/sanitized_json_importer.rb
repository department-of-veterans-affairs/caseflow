# frozen_string_literal: true

require "helpers/sanitized_json_difference.rb"

class SanitizedJsonImporter
  prepend SanitizedJsonDifference

  # input
  attr_accessor :records_hash
  attr_accessor :metadata
  attr_accessor :id_offset

  # output
  attr_accessor :imported_records

  def self.from_file(filename)
    new(File.read(filename))
  end

  def initialize(file_contents, id_offset: 2_000_000_000)
    @id_offset = id_offset
    @records_hash = JSON.parse(file_contents)
    @metadata = @records_hash.delete("metadata")
    @imported_records = {}
  end

  SjConfiguration = SanitizedJsonConfiguration

  def import
    ActiveRecord::Base.transaction do
      SjConfiguration::FIRST_TYPES_TO_IMPORT.each do |clazz|
        import_array_of(clazz)
      end

      SjConfiguration.check_first_imports(imported_records)

      @records_hash.each do |key, obj_hash_array|
        import_array_of(key.classify.constantize, key, obj_hash_array)
      end
    end
    imported_records
  end

  def id_mapping
    # Keep track of id mappings for these record types to reassociate to newly imported records
    @id_mapping ||= SjConfiguration::ID_MAPPING_TYPES.map { |clazz| [clazz.name, {}] }.to_h
  end

  private

  def import_array_of(clazz, key = clazz.table_name, obj_hash_array = @records_hash.fetch(key, []))
    new_records = obj_hash_array.map do |obj_hash|
      fail "No JSON data for records_hash key: #{key}" unless obj_hash

      import_record(clazz, obj_hash)
    end
    imported_records[key] = new_records
    @records_hash.delete(key)
  end

  def import_record(clazz, obj_hash)
    obj_description = "original: #{obj_hash['type']} " \
                      "#{obj_hash.select { |obj_key, _v| obj_key.include?('_id') }}"
    # Don't import if certain types of records already exists
    if SjConfiguration::NONDUPLICATE_TYPES.include?(clazz) && existing_record(clazz, obj_hash)
      puts "  = Using existing #{clazz} instead of importing: #{obj_hash['id']} \n\t#{obj_description}"
      return
    end

    # Record original id in case it changes in the following lines
    orig_id = obj_hash["id"]

    SjConfiguration.adjust_unique_identifiers(clazz, obj_hash).tap do |label|
      if label
        puts "  * Will import duplicate #{clazz} '#{label}' with different unique attributes " \
             "because existing record's id is different: \n\t#{obj_hash}"
      end
    end

    singleton = SjConfiguration.create_singleton(clazz, obj_hash, obj_description)
    return singleton if singleton

    adjust_ids_by_offset(clazz, obj_hash)
    reassociate_with_imported_records(clazz, obj_hash)

    SjConfiguration.before_creation_hook(clazz, obj_hash, obj_description, importer: self)
    create_new_record(orig_id, clazz, obj_hash)
  end

  OFFSET_ID_TABLE_FIELDS = SjConfiguration::OFFSET_ID_FIELDS.transform_keys(&:table_name).freeze

  # :reek:FeatureEnvy
  def adjust_ids_by_offset(clazz, obj_hash)
    obj_hash["id"] += @id_offset

    # Use table_name to handle subclasses/STI: e.g., a HearingTask record maps to table "tasks"
    OFFSET_ID_TABLE_FIELDS[clazz.table_name]&.each do |field_name|
      if obj_hash[field_name].is_a?(Array)
        obj_hash[field_name] = obj_hash[field_name].map { |id| id + @id_offset }
      elsif obj_hash[field_name]
        obj_hash[field_name] += @id_offset
      end
    end
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
    id_mapping[clazz.name][orig_id] = obj_hash["id"] if id_mapping[clazz.name]

    if SjConfiguration::TYPES_THAT_SKIP_VALIDATION_AND_CALLBACKS.include?(clazz)
      # Create the record without validation or callbacks
      new_record = clazz.new(obj_hash)
      new_record.extend(SkipCallbacks) # monkeypatch only this in-memory instance of the record
      new_record.save(validate: false)
      new_record
    else
      clazz.create!(obj_hash)
    end
  end

  REASSOCIATE_TYPE_TABLE_FIELDS = SjConfiguration::REASSOCIATE_FIELDS[:type].transform_keys(&:table_name).freeze
  REASSOCIATE_TABLE_FIELDS_HASH = SjConfiguration::REASSOCIATE_FIELDS
    .select { |type_string, _| type_string.is_a?(String) }
    .transform_values { |class_to_fieldnames_hash| class_to_fieldnames_hash.transform_keys(&:table_name) }.freeze

  # :reek:FeatureEnvy
  def reassociate_with_imported_records(clazz, obj_hash)
    # Handle polymorphic associations (where the association class is stored in the *'_type' field)
    puts "--- Reassociate polymorphic associations for #{clazz.name}"
    REASSOCIATE_TYPE_TABLE_FIELDS[clazz.table_name]&.each do |field_name|
      fail "!!! Expecting field_name to end with '_id' but got: #{field_name}" unless field_name.ends_with?("_id")

      association_type = obj_hash[field_name.sub(/_id$/, "_type")]
      record_id_mapping = id_mapping[association_type]
      reassociate(obj_hash, field_name, record_id_mapping, association_type: association_type)
    end

    # Handle associations where the association class is not stored (it is implied)
    # For each type in REASSOCIATE_TABLE_FIELDS_HASH, iterate through each field_name in reassociate_table_fields
    # and reassociate the field to the imported record
    REASSOCIATE_TABLE_FIELDS_HASH.each do |association_type, reassociate_table_fields|
      puts "--- Reassociate #{clazz.name} fields for #{association_type} associations"
      # record_id_mapping is a hash with key ... TODO
      record_id_mapping = id_mapping[association_type]
      reassociate_table_fields[clazz.table_name]&.each do |field_name|
        reassociate(obj_hash, field_name, record_id_mapping, association_type: association_type)
      end
    end
  end

  def reassociate(obj_hash, id_field, record_id_mapping, association_type: nil)
    orig_record_id = obj_hash[id_field]
    return unless orig_record_id

    obj_hash[id_field] = record_id_mapping[orig_record_id] if record_id_mapping[orig_record_id]
    puts "reassociated #{id_field}: #{association_type} #{orig_record_id}->#{obj_hash[id_field]}"
  end

  def existing_record(clazz, obj_hash)
    existing_record = clazz.find_by_id(obj_hash["id"])
    same_unique_attributes = SjConfiguration.same_unique_attributes?(existing_record, obj_hash, importer: self)
    existing_record if existing_record && same_unique_attributes
  end
end
