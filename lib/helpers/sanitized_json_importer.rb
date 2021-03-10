# frozen_string_literal: true

class SanitizedJsonImporter
  # input
  attr_accessor :records_hash

  # output
  attr_accessor :imported_records

  def self.from_file(filename)
    new(File.read(filename))
  end

  def initialize(file_contents, id_offset: ID_OFFSET)
    @records_hash = JSON.parse(file_contents)
    @imported_records = {}

    # Keep track of id mappings for these record types to reassociate to newly imported records
    @mapped_ids = {
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
        import_array(Veteran, "veterans")

        if appeals.blank?
          puts "WARN: No appeal imported, aborting import of remaining records"
          Rails.logger.warn "No appeal imported, aborting import of remaining records"
          return nil
        end

        import_array(Claimant, "claimants")
        import_array(User, "users")
        import_array(Organization, "organizations")
        import_array(Task, "tasks")
      end
    end
    imported_records
  end

  # Compare tasks
  def self.diff_task_hashes(task_list, appeal)
    a3_tasks = JSON.parse(appeal.tasks.order(:id).to_json(methods: :type))
    a3_hash = a3_tasks.index_by { |t| t["id"] }

    task_list.map do |task|
      task_hash = task.to_h
      hash1 = task_hash
      hash2 = a3_hash[hash1["id"]]
      diff_hashes(hash1, hash2)
    end
  end

  ID_OFFSET = 1_000_000_000

  def self.diff_records(record1, record2, **kwargs)
    hash1 = SanitizedJsonExporter.record_to_hash(record1)
    hash2 = SanitizedJsonExporter.record_to_hash(record2)
    diff_hashes(hash1, hash2, **kwargs)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity:
  def self.diff_hashes(hash1, hash2, ignore_id_offset: true, convert_timestamps: true)
    # https://stackoverflow.com/questions/4928789/how-do-i-compare-two-hashes
    array_diff = (hash2.to_a - hash1.to_a) + (hash1.to_a - hash2.to_a)

    # Ignore some differences if they are expected or equivalent
    array_diff.map(&:first).uniq.inject([]) do |diffs, key|
      if ignore_id_offset && integer?(hash2[key])
        next diffs if (hash2[key].to_i - hash1[key].to_i).abs == ID_OFFSET
      end

      if convert_timestamps && (hash1[key].try(:to_time) || hash2[key].try(:to_time))
        time1 = hash1[key].try(:to_time)&.to_s || hash1[key]
        time2 = hash2[key].try(:to_time)&.to_s || hash2[key]
        next diffs if time1 == time2

        next diffs << [key, time1, time2]
      end

      next diffs << [key, hash1[key], hash2[key]]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity:

  private

  def mapped_appeal_ids
    @mapped_ids[Appeal.name.underscore]
  end

  def mapped_user_ids
    @mapped_ids[User.name.underscore]
  end

  def mapped_org_ids
    @mapped_ids[Organization.name.underscore]
  end

  def import_array(clazz, key)
    obj_hash_array = @records_hash[key]
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
      case kind
      when :save, :create
        # puts "==== Skipping callbacks for #{kind}: #{args}"
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

    existing_record = existing_record(clazz, obj_hash)
    # Don't import if it already exists
    if existing_record && NONDUPLICATE_TYPES.include?(clazz)
      puts "Using existing #{clazz} instead of importing: #{obj_hash['id']} #{obj_hash['type']} #{obj_hash.select { |k, _v| k.include?('_id') }}"
      return
    end

    case clazz.name
    when Organization.name

      if Organization.find_by(url: obj_hash["url"])
        obj_hash["url"] = obj_hash["url"] + "_imported"
        Rails.logger.warn "Importing duplicate organization with different unique url because record id is different: #{obj_hash}"
      elsif Organization.find_by(id: obj_hash["id"]).nil?
        # Try to create the singleton with the same id
        # return if obj_hash["type"].constantize.singleton
        # obj_hash["name"] = obj_hash["name"] + "_imported" if Organization.find_by(name: obj_hash["name"])
        puts "Creating #{clazz} with original id #{obj_hash['id']} #{obj_hash['type']} '#{obj_hash['name']}' #{obj_hash.select { |k, _v| k.include?('_id') }}"
        return clazz.create!(obj_hash)
      end
    when User.name
      # Change CSS_ID if it already exists for a user with different user.id
      obj_hash["css_id"] = obj_hash["css_id"] + "_imported" if User.find_by_css_id(obj_hash["css_id"])
    end

    orig_id = obj_hash["id"]
    adjust_ids(clazz, obj_hash)
    reassociate(clazz, obj_hash)

    puts "Creating #{clazz} #{obj_hash['id']} #{obj_hash['type']} #{obj_hash.select { |k, _v| k.include?('_id') }}"
    case clazz.name
    when Appeal.name
      @mapped_ids[clazz.name.underscore][orig_id] = obj_hash["id"]
    when Task.name
      # Create the task without validation or callbacks
      new_task = Task.new(obj_hash)
      new_task.extend(SkipCallbacks) # patch only this in-memory instance of the task
      new_task.save(validate: false)
      return new_task
    when User.name
      mapped_user_ids[orig_id] = obj_hash["id"]
    when Organization.name
      # Create org with different id
      mapped_org_ids[orig_id] = obj_hash["id"]
    else
      if clazz == Claimant
        # Per appeal, set of participant_ids must be unique
        # pp Claimant.pluck(:id, :type, :participant_id, :decision_review_type, :decision_review_id)
        # binding.pry
      end
    end

    new_record = clazz.create!(obj_hash)
  end

  def reassociate(clazz, obj_hash)
    # pp "Reassociate #{clazz}"
    case clazz.name
    when Claimant.name, VeteranClaimant.name
      obj_hash["decision_review_id"] = mapped_appeal_ids[obj_hash["decision_review_id"]] if mapped_appeal_ids[obj_hash["decision_review_id"]] && obj_hash["decision_review_type"] == "Appeal"
    when Task.name
      obj_hash["appeal_id"] = mapped_appeal_ids[obj_hash["appeal_id"]] if mapped_appeal_ids[obj_hash["appeal_id"]]
      obj_hash["assigned_to_id"] = mapped_user_ids[obj_hash["assigned_to_id"]] if obj_hash["assigned_to_type"] == "User" && mapped_user_ids[obj_hash["assigned_to_id"]]
      obj_hash["assigned_to_id"] = mapped_org_ids[obj_hash["assigned_to_id"]] if obj_hash["assigned_to_type"] == "Organization" && mapped_org_ids[obj_hash["assigned_to_id"]]
      obj_hash["assigned_by_id"] = mapped_user_ids[obj_hash["assigned_by_id"]] if mapped_user_ids[obj_hash["assigned_by_id"]]
    end
  end

  def existing_record(clazz, obj_hash)
    existing_record = clazz.find_by_id(obj_hash["id"])
    existing_record if existing_record && same_unique_attributes?(existing_record, obj_hash)
  end

  def same_unique_attributes?(existing_record, obj_hash)
    case existing_record
    when Organization
      existing_record.url == obj_hash["url"]
    when User
      existing_record.css_id == obj_hash["css_id"]
    when Claimant
      # check if claimant is associated with appeal we just imported
      new_appeal_id = mapped_appeal_ids[obj_hash["decision_review_id"]]
      existing_record.decision_review_id == new_appeal_id
    end
  end

  def adjust_ids(clazz, obj_hash)
    obj_hash["id"] += @id_offset

    case clazz.name
    when Task.name
      obj_hash["parent_id"] += @id_offset if obj_hash["parent_id"]
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
