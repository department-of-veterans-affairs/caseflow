# frozen_string_literal: true

require "helpers/sanitized_json_difference.rb"

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

    # Keep track of id mappings for these record types to reassociate to newly imported records
    @id_mapping = {
      Appeal.name.underscore => {},
      User.name.underscore => {},
      Organization.name.underscore => {}
    }
  end

  def import
    ActiveRecord::Base.transaction do
      import_array_of(Appeal).tap do |appeals|
        if appeals.blank?
          puts "Warning: No appeal imported, aborting import of remaining records"
          return nil
        end

        # Start with important types that other records will reassociate with
        import_array_of(User)
        import_array_of(Organization)

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
  NONDUPLICATE_TYPES = [Organization, User, Veteran].freeze

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
    remaining_id_fields = obj_hash.select do |k, v|
      k.ends_with?("_id") && v.is_a?(Integer) && (v < @id_offset) &&
        !(clazz <= Task && obj_hash["assigned_to_type"] == "Organization" && k == "assigned_to_id")
    end
    puts "!! Need offset?: #{remaining_id_fields}" unless remaining_id_fields.blank?
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
    elsif clazz <= CavcRemand
      # Avoid "Validation failed: Cavc judge full name is not included in the list"
      # obj_hash["cavc_judge_full_name"] = Constants::CAVC_JUDGE_FULL_NAMES.sample
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  # :reek:FeatureEnvy
  def adjust_ids_by_offset(clazz, obj_hash)
    obj_hash["id"] += @id_offset

    if clazz <= Task
      obj_hash["appeal_id"] += @id_offset
      obj_hash["parent_id"] += @id_offset if obj_hash["parent_id"]
    elsif clazz <= Claimant
      obj_hash["decision_review_id"] += @id_offset
    elsif clazz <= TaskTimer
      obj_hash["task_id"] += @id_offset
    elsif clazz <= AppealIntake
      obj_hash["detail_id"] += @id_offset
    elsif clazz <= CavcRemand
      obj_hash["source_appeal_id"] += @id_offset
      obj_hash["remand_appeal_id"] += @id_offset
      obj_hash["decision_issue_ids"] = obj_hash["decision_issue_ids"].map { |id| id + @id_offset }
    elsif clazz <= OrganizationsUser
      obj_hash["user_id"] += @id_offset
      obj_hash["organization_id"] += @id_offset
    elsif clazz <= DecisionIssue
      obj_hash["decision_review_id"] += @id_offset
    elsif clazz <= RequestIssue
      obj_hash["decision_review_id"] += @id_offset
      obj_hash["contested_decision_issue_id"] += @id_offset
    elsif clazz <= RequestDecisionIssue
      obj_hash["request_issue_id"] += @id_offset
      obj_hash["decision_issue_id"] += @id_offset
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

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

  ID_MAPPING_TYPES = [Appeal, User, Organization].freeze

  # :reek:FeatureEnvy
  def create_new_record(orig_id, clazz, obj_hash)
    # Record new id for certain record types
    @id_mapping[clazz.name.underscore][orig_id] = obj_hash["id"] if ID_MAPPING_TYPES.include?(clazz)

    if clazz <= Task
      # Create the task without validation or callbacks
      new_task = Task.new(obj_hash)
      new_task.extend(SkipCallbacks) # monkeypatch only this in-memory instance of the task
      new_task.save(validate: false)
      return new_task
    end

    clazz.create!(obj_hash)
  end

  def appeal_id_mapping
    @id_mapping[Appeal.name.underscore]
  end

  def user_id_mapping
    @id_mapping[User.name.underscore]
  end

  def org_id_mapping
    @id_mapping[Organization.name.underscore]
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # :reek:FeatureEnvy
  def reassociate_with_imported_records(clazz, obj_hash)
    # pp "Reassociate #{clazz}"
    if clazz <= Task
      reassociate(obj_hash, "assigned_by_id", user_id_mapping)

      if obj_hash["assigned_to_type"] == "User"
        reassociate(obj_hash, "assigned_to_id", user_id_mapping)
      elsif obj_hash["assigned_to_type"] == "Organization"
        reassociate(obj_hash, "assigned_to_id", org_id_mapping)
      end
    elsif clazz <= AppealIntake
      reassociate(obj_hash, "user_id", user_id_mapping)
    elsif clazz <= CavcRemand
      reassociate(obj_hash, "created_by_id", user_id_mapping)
      reassociate(obj_hash, "updated_by_id", user_id_mapping)
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def reassociate(obj_hash, id_field, record_id_mapping)
    obj_hash[id_field] = record_id_mapping[obj_hash[id_field]] if record_id_mapping[obj_hash[id_field]]
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
      new_appeal_id = appeal_id_mapping[obj_hash["decision_review_id"]]
      existing_record.decision_review_id == new_appeal_id
    end
  end

  private_class_method def self.integer?(thing)
    begin
      Integer(thing)
    rescue StandardError
      false
    end
  end
end
