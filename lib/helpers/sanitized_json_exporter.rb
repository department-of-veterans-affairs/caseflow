# frozen_string_literal: true

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  # :reek:BooleanParameter
  def initialize(*initial_appeals, sanitize: true)
    @sanitize = sanitize
    @value_mapping = {}
    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }

    associated_appeals = initial_appeals.map { |appeal| appeals_associated_with(appeal) }.flatten.uniq.compact
    appeals = initial_appeals + associated_appeals
    tasks = appeals.map(&:tasks).flatten.sort_by(&:id).extend(TaskAssignment)

    {
      Appeal => appeals,
      Veteran => appeals.map(&:veteran),
      Claimant => appeals.map(&:claimants).flatten,
      Task => tasks,
      TaskTimer => TaskTimer.where(task_id: tasks.map(&:id)),
      User => tasks.map(&:assigned_by).compact + tasks.assigned_to_user.map(&:assigned_to),
      Organization => tasks.assigned_to_org.map(&:assigned_to)
    }.each do |clazz, records|
      @records_hash[clazz.table_name] = sanitize_records(records)
    end
  end

  def appeals_associated_with(appeal)
    appeal.cavc_remand&.source_appeal
    # To-do: include other source appeals, e.g., those with the same docket number
  end

  def save(filename, purpose: nil)
    @records_hash["metadata"]["purpose"] = purpose if purpose
    File.open(filename.to_s, "w") { |file| file.puts file_contents }
  end

  def file_contents
    JSON.pretty_generate(@records_hash)
  end

  # temporary method; delete for final PR
  # :reek:BooleanParameter
  def self.record_to_hash(record, call_attributes: true)
    return record.attributes if call_attributes

    # Alternative implementation
    json_string = record.to_json(methods: :type)
    JSON.parse(json_string)
  end

  private

  module TaskAssignment
    def assigned_to_user
      select { |task| task.assigned_to_type == "User" }
    end

    def assigned_to_org
      select { |task| task.assigned_to_type == "Organization" }
    end
  end

  def sanitize_records(records)
    # keep records in order so that comparisons can be done after import
    records.uniq.sort_by(&:id).map { |veteran| sanitize(veteran) }
  end

  VETERAN_PII_FIELDS = %w[first_name last_name middle_name file_number ssn].freeze

  def sanitize(record)
    obj_hash = self.class.record_to_hash(record)
    return obj_hash unless @sanitize

    case record
    when Appeal
      find_or_create_mapped_value_for(obj_hash, "veteran_file_number")
    when Veteran
      VETERAN_PII_FIELDS.each do |field|
        find_or_create_mapped_value_for(obj_hash, field)
      end
    when User
      # User#attributes includes `display_name`; don't need it when importing so leave it out
      obj_hash.delete(:display_name)
      find_or_create_mapped_value_for(obj_hash, "full_name")
      find_or_create_mapped_value_for(obj_hash, "email")
      find_or_create_mapped_value_for(obj_hash, "css_id")

      # obj_hash["my_name"]="AAA BBB"
      # find_or_create_mapped_value_for(obj_hash, "my_name")
    when Organization, Claimant, Task, TaskTimer
      # nothing to sanitize
      obj_hash
    else
      fail "Unsupported object type: #{record.class.name}"
    end

    obj_hash
  end

  def find_or_create_mapped_value_for(obj_hash, field_name)
    return unless obj_hash[field_name]

    # Loop to ensure value_mapping has different values for different keys
    loop do
      obj_hash[field_name] = find_or_create_mapped_value(obj_hash[field_name], field_name)
      break if value_mapping.values.uniq.size == value_mapping.size

      puts "Value '#{obj_hash[field_name]}' for field #{field_name} is already used; trying again"
    end
  end

  TRANSFORM_METHODS = [:mixup_css_id, :random_person_name, :invalid_ssn, :random_email].freeze

  def find_or_create_mapped_value(orig_value, field_name = nil)
    mapped_value = value_mapping.fetch(orig_value) do
      TRANSFORM_METHODS.find { |method| value_mapping[orig_value] = self.class.send(method, field_name, orig_value) }
      value_mapping[orig_value]
    end
    mapped_value || fail("Don't know how to map value '#{orig_value}' for field '#{field_name}'")
  end

  class << self
    # :reek:RepeatedConditionals
    def random_email(field_name, field_value)
      case field_name
      when /email$/
        Faker::Internet.email
      else
        case field_value
        when /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
          Faker::Internet.email
        end
      end
    end

    def invalid_ssn(field_name, field_value)
      # instead of using Faker::IDNumber.invalid, make the SSN obviously fake by starting with '000'
      case field_name
      when "ssn", "file_number", "veteran_file_number"
        "000#{Faker::Number.number(digits: 6)}"
      else
        case field_value
        when /^\d{9}$/
          "000#{Faker::Number.number(digits: 6)}"
        when /^\d{3}-\d{2}-\d{4}$/
          ["000", Faker::Number.number(digits: 2), Faker::Number.number(digits: 4)].join("-")
        end
      end
    end

    def random_person_name(field_name, _field_value)
      case field_name
      when "full_name"
        "#{Faker::Name.first_name} #{Faker::Name.last_name}"
      when "last_name"
        Faker::Name.last_name
      when "middle_name"
        Faker::Name.initials(number: 1)
      when "first_name"
        Faker::Name.first_name
      when /_name$/
        # puts "NAME_REGEX for #{field_name}"
        Faker::Name.first_name
      end
    end

    # Keep field value recognizable but different to reduce risk of exploitation (e.g., username scraping)
    def mixup_css_id(field_name, field_value)
      case field_name
      when "css_id"
        field_value[4..-1] + field_value[0..3]
      end
    end

    def obfuscate_sentence(_field_name, field_value)
      field_value.split.map { |word| word[0..1] }.join(" ")
    end
  end
end
