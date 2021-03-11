# frozen_string_literal: true

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  # :reek:BooleanParameter
  def initialize(*appeals, sanitize: true)
    @sanitize = sanitize
    @value_mapping = {}
    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }

    appeals.uniq!
    @records_hash["appeals"] = appeals.map { |appeal| sanitize(appeal) }

    other_appeals = appeals.map { |appeal| associated_appeals(appeal) }.flatten.uniq.compact
    @records_hash["appeals"] += other_appeals.map { |appeal| sanitize(appeal) }

    relevant_appeals = appeals + other_appeals
    export_claimants(relevant_appeals)
    export_tasks(relevant_appeals)
  end

  def associated_appeals(appeal)
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

  def export_claimants(appeals)
    @records_hash["veterans"] = appeals.map(&:veteran).uniq.map { |veteran| sanitize(veteran) }
    @records_hash["claimants"] = appeals.map(&:claimants).flatten.uniq.sort_by(&:id).map do |claimant|
      sanitize(claimant)
    end
  end

  def export_tasks(appeals)
    tasks = appeals.map(&:tasks).flatten.sort_by(&:id)
    @records_hash["tasks"] = tasks.map { |task| sanitize(task) }

    users = tasks.sort_by(&:id).map(&:assigned_by).compact +
            tasks.select { |task| task.assigned_to_type == "User" }.sort_by(&:id).map(&:assigned_to)
    @records_hash["users"] = users.uniq.map { |user| sanitize(user) }

    @records_hash["organizations"] = tasks.select { |task| task.assigned_to_type == "Organization" }.sort_by(&:id)
      .map(&:assigned_to).uniq.map { |org| sanitize(org) }
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
    when Organization, Claimant, Task
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

    # https://github.com/faker-ruby/faker/blob/master/doc/default/id_number.md
    def invalid_ssn(field_name, field_value)
      case field_name
      when "ssn", "file_number", "veteran_file_number"
        Faker::IDNumber.invalid.delete("-")
      else
        case field_value
        when /^\d{9}$/
          Faker::IDNumber.invalid.delete("-")
        when /^\d{3}-\d{2}-\d{4}$/
          Faker::IDNumber.invalid
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
