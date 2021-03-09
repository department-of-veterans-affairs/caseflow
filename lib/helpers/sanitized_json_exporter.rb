# frozen_string_literal: true

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  def initialize(record, sanitize: true)
    @record = record
    @sanitize = sanitize
    @value_mapping = {}

    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }
    @records_hash[record.class.name] = sanitize(record)
    @records_hash[record.veteran.class.name] = sanitize(record.veteran)

    @records_hash[Claimant.name] = sanitize(record.claimant)
    @records_hash["claimants"] =
      record.claimants.order(:id).map { |claimant| sanitize(claimant) }

    @records_hash["tasks"] =
      record.tasks.order(:id).map { |task| sanitize(task) }

    assigned_to_users = record.tasks.where(assigned_to_type: "User").order(:id).map(&:assigned_to) +
                        record.tasks.order(:id).map(&:assigned_by).compact
    @records_hash["users"] = assigned_to_users.uniq.map { |user| sanitize(user) }

    @records_hash["organizations"] = record.tasks.where(assigned_to_type: "Organization").order(:id)
      .map(&:assigned_to).uniq.map { |org| sanitize(org) }
  end

  def save(filename, purpose: nil)
    @records_hash["metadata"]["purpose"] = purpose if purpose
    File.open(filename.to_s, "w") { |file| file.puts file_contents }
  end

  def file_contents
    JSON.pretty_generate(@records_hash)
  end

  def self.to_hash(record)
    return record.attributes if true

    # Alternative implementation
    json_string = record.to_json(methods: :type)
    JSON.parse(json_string)
  end

  private

  VETERAN_PII_FIELDS = %w[first_name last_name middle_name file_number ssn].freeze

  def sanitize(record)
    obj_hash = self.class.to_hash(record)
    return obj_hash unless @sanitize

    case record
    when Appeal
      find_or_create_mapped_value_for(obj_hash, "veteran_file_number")
    when Veteran
      VETERAN_PII_FIELDS.each do |field|
        find_or_create_mapped_value_for(obj_hash, field)
      end
    when Claimant
    when Task
      ## TODO: Re-associate during import
      # obj_hash["decision_review_id"] = @record.id
    when User
      # User#attributes includes `display_name`; don't need it when importing so leave it out
      obj_hash.delete(:display_name)
    when Organization
    else
      fail "Unsupported object type: #{record.class.name}"
    end

    obj_hash
  end

  def find_or_create_mapped_value_for(obj_hash, fieldname)
    return unless obj_hash[fieldname]

    # Ensure value_mapping has different values for different keys
    loop do
      obj_hash[fieldname] = find_or_create_mapped_value(obj_hash[fieldname], fieldname)
      break if value_mapping.values.uniq.size == value_mapping.size
    end
  end

  SSN_REGEX = /^\d{9}$/.freeze
  NAME_REGEX = /_name$/.freeze

  def find_or_create_mapped_value(orig_value, field_name = nil)
    return value_mapping[orig_value] if value_mapping[orig_value]

    return value_mapping[orig_value] if (value_mapping[orig_value] = create_person_name(field_name))

    return value_mapping[orig_value] = Faker::Name.first_name if orig_value.match?(NAME_REGEX)

    if ssn_field?(field_name) || orig_value.match?(SSN_REGEX)
      # https://github.com/faker-ruby/faker/blob/master/doc/default/id_number.md
      return value_mapping[orig_value] = Faker::IDNumber.invalid.delete("-")
    end

    fail "Don't know how to map value '#{orig_value}' for field '#{field_name}'"
  end

  def ssn_field?(field_name)
    %w[ssn file_number veteran_file_number].include?(field_name)
  end

  def create_person_name(field_name)
    case field_name
    when "first_name"
      Faker::Name.first_name
    when "last_name"
      Faker::Name.last_name
    when "middle_name"
      Faker::Name.initials(number: 1)
    end
  end
end
