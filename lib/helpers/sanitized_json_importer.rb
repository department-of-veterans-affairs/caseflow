# frozen_string_literal: true

class SanitizedJsonImporter
  attr_accessor :imported_records
  attr_accessor :records_hash

  def initialize(input, id_offset: 2_000_000_000)
    file_contents = File.exist?(input) ? File.read(input) : input
    @records_hash = JSON.parse(file_contents)
    @imported_records = {}
    @imported_users = {}

    @id_offset = id_offset
  end

  def metadata
    @records_hash["metadata"]
  end

  def import_all(all_claimants: true)
    appeal = import(Appeal)
    import(Veteran)
    if all_claimants
      import_array(Claimant, "claimants")
    else
      import(Claimant) # associated to appellant via participant id
    end
    import_array(User, "users")
    import_array(Organization, "organizations")
    import_array(Task, "tasks")

    appeal
  end

  def import_array(clazz, key)
    obj_hash_array = @records_hash[key]
    obj_hash_array.map do |obj_hash|
      import(clazz, obj_hash: obj_hash)
    end
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
      else
        super
      end
      yield(*args) if block_given?
    end
  end

  def import(clazz, key: clazz.name, obj_hash: @records_hash[key])
    fail "No JSON data for key '#{key}'.  Keys: #{@records_hash.keys}" unless obj_hash

    case clazz.name
    when Organization.name
      # Don't import if it already exists
      return if Organization.find_by(url: obj_hash["url"])

      # Try to create the singleton
      return if obj_hash["type"].constantize.singleton
    when User.name
      # Change CSS_ID if it already exists
      obj_hash["css_id"] = obj_hash["css_id"] + "_imported" if User.find_by(css_id: obj_hash["css_id"])
    end

    orig_id = obj_hash["id"]
    adjust_ids(clazz, obj_hash)
    reassociate(clazz, obj_hash)
    case clazz.name
    when Task.name
      # Create the task without validation or callbacks
      new_task = Task.new(obj_hash)
      new_task.extend(SkipCallbacks) # patch only this in-memory instance of the task
      new_task.save(validate: false)
      new_task
    when User.name
      @imported_users[orig_id] = obj_hash["id"]
      clazz.create!(obj_hash).tap { |new_record| imported_records[key] = new_record }
    else
      clazz.create!(obj_hash).tap { |new_record| imported_records[key] = new_record }
    end
  end

  def reassociate(clazz, obj_hash)
    case clazz.name
    when Claimant.name
      obj_hash["decision_review_id"] = imported_records[Appeal.name].id
    when Task.name
      obj_hash["appeal_id"] = imported_records[Appeal.name].id
      obj_hash["assigned_to_id"] = @imported_users[obj_hash["assigned_to_id"]] if obj_hash["assigned_to_type"] == "User" && @imported_users[obj_hash["assigned_to_id"]]
      obj_hash["assigned_by_id"] = @imported_users[obj_hash["assigned_by_id"]] if @imported_users[obj_hash["assigned_by_id"]]
    end
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

  ID_OFFSET = 2_000_000_000

  def self.diff_records(record1, record2, **kwargs)
    hash1 = SanitizedJsonExporter.to_hash(record1)
    hash2 = SanitizedJsonExporter.to_hash(record2)
    diff_hashes(hash1, hash2, **kwargs)
  end

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

  private

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
