# frozen_string_literal: true

class SanitizedJsonImporter
  # input
  attr_accessor :records_hash

  # output
  attr_accessor :imported_records

  def self.from_file(filename)
    new(File.read(filename))
  end

  ID_OFFSET = 2_000_000_000

  def initialize(file_contents, id_offset: ID_OFFSET)
    @records_hash = JSON.parse(file_contents)
    @imported_records = {}

    # Keep track of id mappings for these record types to reassociate to newly imported records
    @id_mapping = {
      Appeal.name.underscore => {},
      User.name.underscore => {},
      Organization.name.underscore => {}
    }

    @id_offset = id_offset
  end

  def metadata
    @records_hash["metadata"]
  end

  def import
    ActiveRecord::Base.transaction do
      import_array(Appeal, "appeals").tap do |appeals|
        if appeals.blank?
          puts "Warning: No appeal imported, aborting import of remaining records"
          return nil
        end

        import_array(Veteran, "veterans")
        import_array(Claimant, "claimants")

        import_array(User, "users")
        import_array(Organization, "organizations")
        import_array(Task, "tasks")
      end
    end
    imported_records
  end

  # TODO: These 3 diff_* methods will be refactored later
  # Compare tasks
  def self.diff_task_hashes(task_list, appeal)
    a3_tasks = JSON.parse(appeal.tasks.order(:id).to_json(methods: :type))
    a3_hash = a3_tasks.index_by { |task| task["id"] }

    task_list.map do |task|
      diff_hashes(task.to_h, a3_hash[task_hash["id"]])
    end
  end

  def self.diff_records(record_a, record_b, **kwargs)
    hash_a = SanitizedJsonExporter.record_to_hash(record_a)
    hash_b = SanitizedJsonExporter.record_to_hash(record_b)
    diff_hashes(hash_a, hash_b, **kwargs)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
  # :reek:BooleanParameter
  # :reek:LongParameterList
  def self.diff_hashes(hash_a, hash_b, ignore_id_offset: true, convert_timestamps: true)
    # https://stackoverflow.com/questions/4928789/how-do-i-compare-two-hashes
    array_diff = (hash_b.to_a - hash_a.to_a) + (hash_a.to_a - hash_b.to_a)

    # Ignore some differences if they are expected or equivalent
    array_diff.map(&:first).uniq.inject([]) do |diffs, key|
      if ignore_id_offset && integer?(hash_b[key])
        next diffs if (hash_b[key].to_i - hash_a[key].to_i).abs == ID_OFFSET
      end

      if convert_timestamps && (hash_a[key].try(:to_time) || hash_b[key].try(:to_time))
        time_a = hash_a[key].try(:to_time)&.to_s || hash_a[key]
        time_b = hash_b[key].try(:to_time)&.to_s || hash_b[key]
        next diffs if time_a == time_b

        next diffs << [key, time_a, time_b]
      end

      next diffs << [key, hash_a[key], hash_b[key]]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity

  private

  def import_array(clazz, key)
    obj_hash_array = @records_hash.fetch(key, [])
    new_records = obj_hash_array.map do |obj_hash|
      import_record(clazz, obj_hash: obj_hash)
    end
    imported_records[key] = new_records
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

  # Classes that shouldn't be imported if a record with the same unique attributes already exists
  NONDUPLICATE_TYPES = [Organization, User, Veteran].freeze

  def import_record(clazz, key: clazz.name, obj_hash: @records_hash[key])
    fail "No JSON data for key '#{key}'.  Keys: #{@records_hash.keys}" unless obj_hash

    obj_description = "\n\t#{obj_hash['type']} " \
                      "#{obj_hash.select { |obj_key, _v| obj_key.include?('_id') }}"
    # Don't import if certain types of records already exists
    if NONDUPLICATE_TYPES.include?(clazz) && existing_record(clazz, obj_hash)
      puts "  = Using existing #{clazz} instead of importing: #{obj_hash['id']} #{obj_description}"
      return
    end

    # Record original id in case it changes in the following lines
    orig_id = obj_hash["id"]

    adjust_unique_identifiers(clazz, obj_hash)

    # Handle Organization type specially because each organization has a `singleton`
    # To-do: update dev's seed data to match prod's Organization#singleton record ids
    if clazz == Organization && !org_already_exists?(obj_hash)
      puts "  + Creating #{clazz} '#{obj_hash['name']}' with its original id #{obj_hash['id']} #{obj_description}"
      return clazz.create!(obj_hash)
    end

    adjust_ids_by_offset(clazz, obj_hash)
    reassociate_with_imported_records(clazz, obj_hash)

    puts "  + Creating #{clazz} #{obj_hash['id']} #{obj_description}"
    create_new_record(orig_id, clazz, obj_hash)
  end

  def org_already_exists?(obj_hash)
    Organization.find_by(url: obj_hash["url"]) || Organization.find_by(id: obj_hash["id"])
  end

  # :reek:FeatureEnvy
  def adjust_unique_identifiers(clazz, obj_hash)
    label = if clazz <= Organization
              obj_hash["url"] += "_imported" if Organization.find_by(url: obj_hash["url"])
            elsif clazz <= User
              # Change CSS_ID if it already exists for a user with different user.id
              obj_hash["css_id"] += "_imported" if User.find_by_css_id(obj_hash["css_id"])
            end
    if label
      puts "  * Will import duplicate #{clazz} '#{label}' with different unique attributes " \
           "because existing record's id is different: \n\t#{obj_hash}"
    end
  end

  # :reek:FeatureEnvy
  def adjust_ids_by_offset(clazz, obj_hash)
    obj_hash["id"] += @id_offset

    if clazz <= Task
      obj_hash["parent_id"] += @id_offset if obj_hash["parent_id"]
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
      new_task.extend(SkipCallbacks) # patch only this in-memory instance of the task
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
    if clazz <= Claimant
      if obj_hash["decision_review_type"] == "Appeal"
        reassociate(obj_hash, "decision_review_id", appeal_id_mapping)
      else
        puts "To-do: HLR, SC, LegacyAppeal"
      end
    elsif clazz <= Task
      reassociate(obj_hash, "appeal_id", appeal_id_mapping)
      reassociate(obj_hash, "assigned_by_id", user_id_mapping)

      if obj_hash["assigned_to_type"] == "User"
        reassociate(obj_hash, "assigned_to_id", user_id_mapping)
      elsif obj_hash["assigned_to_type"] == "Organization"
        reassociate(obj_hash, "assigned_to_id", org_id_mapping)
      end
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
