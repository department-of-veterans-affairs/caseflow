# frozen_string_literal: true

require "helpers/sanitized_json_difference.rb"
# require "helpers/sanitized_json_exporter.rb"

class SanitizedJsonImporter
  prepend SanitizedJsonDifference

  # input
  attr_accessor :records_hash
  attr_accessor :metadata

  # output
  attr_accessor :imported_records

  def self.from_file(filename)
    new(File.read(filename))
  end

  ID_OFFSET = 2_000_000_000

  def initialize(file_contents, id_offset: ID_OFFSET)
    @id_offset = id_offset
    @records_hash = JSON.parse(file_contents)
    @metadata = @records_hash.delete("metadata")
    @imported_records = {}
  end

  def import
    ActiveRecord::Base.transaction do
      import_array_of(Appeal).tap do |appeals|
        return puts "Warning: No appeal imported, aborting import of remaining records" if appeals.blank?

        # Start with important types that other records will reassociate with
        import_array_of(User)
        import_array_of(Organization)

        # HearingDay is needed for Hearing records to be created
        import_array_of(HearingDay)

        @records_hash.except("metadata").each do |key, obj_hash_array|
          import_array_of(key.classify.constantize, key, obj_hash_array)
        end
      end
    end
    imported_records
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

  # Classes that shouldn't be imported if a record with the same unique attributes already exists
  NONDUPLICATE_TYPES = [Organization, User, Veteran, Person].freeze

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
  def import_record(clazz, obj_hash)
    obj_description = "\n\tfrom original#{obj_hash['type']} " \
                      "#{obj_hash.select { |obj_key, _v| obj_key.include?('_id') }}"
    # Don't import if certain types of records already exists
    if NONDUPLICATE_TYPES.include?(clazz) && existing_record(clazz, obj_hash)
      puts "  = Using existing #{clazz} instead of importing: #{obj_hash['id']} #{obj_description}"
      return
    end

    # Record original id in case it changes in the following lines
    orig_id = obj_hash["id"]

    adjust_unique_identifiers(clazz, obj_hash).tap do |label|
      if label
        puts "  * Will import duplicate #{clazz} '#{label}' with different unique attributes " \
             "because existing record's id is different: \n\t#{obj_hash}"
      end
    end

    # Handle Organization type specially because each organization has a `singleton`
    # To-do: update dev's seed data to match prod's Organization#singleton record ids
    if clazz == Organization && !org_already_exists?(obj_hash)
      puts "  + Creating #{clazz} '#{obj_hash['name']}' with its original id #{obj_hash['id']} #{obj_description}"
      return clazz.create!(obj_hash)
    end

    adjust_ids_by_offset(clazz, obj_hash)
    reassociate_with_imported_records(clazz, obj_hash)

    puts "  + Creating #{clazz} #{obj_hash['id']} #{obj_description}"
    remaining_id_fields = obj_hash.select do |field_name, field_value|
      field_name.ends_with?("_id") && field_value.is_a?(Integer) && (field_value < @id_offset) &&
        (
          !(clazz <= Task && field_name == "assigned_to_id" && obj_hash["assigned_to_type"] == "Organization") &&
          !(clazz <= OrganizationsUser && field_name == "organization_id")
          # !(clazz <= OrganizationsUser && field_name == "user_id")
        )
    end
    fail "!! For #{clazz}, expecting these *'_id' fields be adjusted: #{remaining_id_fields}\n\tobj_hash: #{obj_hash}" unless remaining_id_fields.blank?

    create_new_record(orig_id, clazz, obj_hash)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity

  def org_already_exists?(obj_hash)
    Organization.find_by(url: obj_hash["url"]) || Organization.find_by(id: obj_hash["id"])
  end

  # :reek:FeatureEnvy
  def adjust_unique_identifiers(clazz, obj_hash)
    if clazz <= Organization
      obj_hash["url"] += "_imported" if Organization.find_by(url: obj_hash["url"])
    elsif clazz <= User
      # Change CSS_ID if it already exists for a user with different user.id
      obj_hash["css_id"] += "_imported" if User.find_by_css_id(obj_hash["css_id"])
    end
  end

  OFFSET_ID_TABLE_FIELDS = SanitizedJsonExporter::OFFSET_ID_FIELDS.transform_keys(&:table_name).freeze

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
  # rubocop:enable

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

  def id_mapping
    # Keep track of id mappings for these record types to reassociate to newly imported records
    @id_mapping ||= SanitizedJsonExporter::ID_MAPPING_TYPES.map { |clazz| [clazz.name, {}] }.to_h
  end

  SKIP_VALIDATION_AND_CALLBACKS_TYPES = [Task].map(&:table_name).freeze

  # :reek:FeatureEnvy
  def create_new_record(orig_id, clazz, obj_hash)
    # Record new id for certain record types
    id_mapping[clazz.name][orig_id] = obj_hash["id"] if id_mapping[clazz.name]

    if SKIP_VALIDATION_AND_CALLBACKS_TYPES.include?(clazz.table_name)
      # Create the task without validation or callbacks
      new_task = clazz.new(obj_hash)
      new_task.extend(SkipCallbacks) # monkeypatch only this in-memory instance of the task
      new_task.save(validate: false)
      new_task
    else
      clazz.create!(obj_hash)
    end
  end

  REASSOCIATE_TYPE_TABLE_FIELDS = SanitizedJsonExporter::REASSOCIATE_FIELDS[:type].transform_keys(&:table_name).freeze
  REASSOCIATE_TABLE_FIELDS_HASH = SanitizedJsonExporter::REASSOCIATE_FIELDS
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
    existing_record if existing_record && same_unique_attributes?(existing_record, obj_hash)
  end

  # :reek:FeatureEnvy
  def same_unique_attributes?(existing_record, obj_hash)
    case existing_record
    when Organization
      existing_record.url == obj_hash["url"]
    when User
      existing_record.css_id == obj_hash["css_id"]
    when Claimant
      # check if claimant is associated with appeal we just imported
      imported_appeal_id = id_mapping[Appeal.name][obj_hash["decision_review_id"]]
      existing_record.decision_review_id == imported_appeal_id
    when Person
      # To-do: Person.connection.index_exists? :people, :participant_id
      # To-do: ActiveRecord::Base.connection.indexes(Person.table_name).select{|idx| idx.unique}
      existing_record.participant_id == obj_hash["participant_id"]
    end
  end
end
