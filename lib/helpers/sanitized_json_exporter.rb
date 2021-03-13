# frozen_string_literal: true

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  # :reek:BooleanParameter
  def initialize(*initial_appeals, sanitize: true)
    @sanitize = sanitize
    @value_mapping = {}
    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }

    records_to_export(initial_appeals).each do |clazz, records|
      # puts "Exporting #{clazz.table_name}"
      @records_hash[clazz.table_name] = sanitize_records(records)
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def records_to_export(initial_appeals)
    associated_appeals = initial_appeals.map { |appeal| appeals_associated_with(appeal) }.flatten.uniq.compact
    appeals = (initial_appeals + associated_appeals).uniq
    tasks = appeals.map(&:tasks).flatten.sort_by(&:id).extend(TaskAssignment)
    cavc_remands = appeals.map(&:cavc_remand).compact
    hearings = tasks.with_type("HearingTask").map(&:hearing).uniq.compact

    users = tasks.map(&:assigned_by).compact +
            tasks.assigned_to_user.map(&:assigned_to) +
            cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten.uniq.compact +
            appeals.map(&:intake).compact.map(&:user).uniq.compact +
            hearings.map { |h| [h.created_by, h.updated_by, h.judge] }.flatten.uniq.compact +
            hearings.map(&:virtual_hearing).uniq.compact.map { |vh| [vh.created_by, vh.updated_by] }.flatten.uniq.compact

    request_issues = appeals.map(&:request_issues).flatten
    {
      Appeal => appeals,
      AppealIntake => appeals.map(&:intake),
      Veteran => appeals.map(&:veteran),
      Claimant => appeals.map(&:claimants).flatten,
      Task => tasks,
      TaskTimer => TaskTimer.where(task_id: tasks.map(&:id)),
      User => users,
      Organization => tasks.assigned_to_org.map(&:assigned_to) + users.map(&:organizations).flatten.uniq,
      OrganizationsUser => OrganizationsUser.where(user: users),
      CavcRemand => cavc_remands,
      DecisionIssue => appeals.map(&:decision_issues).flatten,
      RequestIssue => request_issues,
      RequestDecisionIssue => RequestDecisionIssue.where(request_issue: request_issues),
      Hearing => hearings,
      HearingTaskAssociation => HearingTaskAssociation.where(hearing: hearings),
      HearingDay => hearings.map(&:hearing_day).uniq.compact,
      VirtualHearing => hearings.map(&:virtual_hearing).uniq.compact
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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

    def with_type(task_type)
      select { |task| task.type == task_type }
    end
  end

  def sanitize_records(records)
    # keep records in order so that comparisons can be done after import
    records.uniq.compact.sort_by(&:id).map { |record| sanitize(record) }
  end

  VETERAN_PII_FIELDS = %w[first_name last_name middle_name file_number ssn].freeze

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def sanitize(record)
    obj_hash = self.class.record_to_hash(record)
    return obj_hash unless @sanitize

    case record
    when Appeal, AppealIntake
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
    when Task
      find_or_create_mapped_value_for(obj_hash, "instructions")
    when Organization, Claimant, TaskTimer, OrganizationsUser, RequestDecisionIssue, HearingTaskAssociation
      # nothing to sanitize
      obj_hash
    when CavcRemand
      # cavc_judge_full_name is selected from Constants::CAVC_JUDGE_FULL_NAMES; no need to sanitize
      # find_or_create_mapped_value_for(obj_hash, "cavc_judge_full_name")
      find_or_create_mapped_value_for(obj_hash, "instructions")
    when DecisionIssue
      find_or_create_mapped_value_for(obj_hash, "description")
      find_or_create_mapped_value_for(obj_hash, "decision_text")
    when RequestIssue
      find_or_create_mapped_value_for(obj_hash, "notes")
      obj_hash.keys.select { |k| k.match?(/_(notes|text|description)/) }.each do |key|
        find_or_create_mapped_value_for(obj_hash, key)
      end
    when Hearing
      find_or_create_mapped_value_for(obj_hash, "notes")
      find_or_create_mapped_value_for(obj_hash, "military_service")
      find_or_create_mapped_value_for(obj_hash, "summary")
      find_or_create_mapped_value_for(obj_hash, "bva_poc")
      find_or_create_mapped_value_for(obj_hash, "representative_name")
      find_or_create_mapped_value_for(obj_hash, "witness")
    when VirtualHearing
      %w[alias guest_pin host_pin guest_pin_long host_pin_long representative_email
         judge_email
         alias_with_host
         appellant_email
         host_hearing_link
         guest_hearing_link].each do |field_name|
        find_or_create_mapped_value_for(obj_hash, field_name)
      end
    when HearingDay
      find_or_create_mapped_value_for(obj_hash, "bva_poc")
      find_or_create_mapped_value_for(obj_hash, "notes")
    else
      fail "Unsupported object type: #{record.class.name}"
    end

    obj_hash
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  def find_or_create_mapped_value_for(obj_hash, field_name)
    return unless obj_hash[field_name]

    # Loop to ensure hash @value_mapping has a different value for each distinct key
    10.times do
      obj_hash[field_name] = find_or_create_mapped_value(obj_hash[field_name], field_name)
      break if @value_mapping.values.uniq.size == @value_mapping.size

      puts "Value '#{obj_hash[field_name]}' for field #{field_name} is already used; trying again"
    end
    obj_hash[field_name]
  end

  # fields whose mapped value should not be saved to the @value_mapping hash,
  # e.g., due to distinct orig_values mapping to the same new_value
  MAPPED_VALUES_IGNORED_FIELDS = %w[instructions descriptions].freeze

  def find_or_create_mapped_value(orig_value, field_name = nil)
    mapped_value = @value_mapping.fetch(orig_value) do
      new_value, transform = transform_value(orig_value, field_name)
      if transform != :obfuscate_sentence && !MAPPED_VALUES_IGNORED_FIELDS.include?(field_name)
        @value_mapping[orig_value] = new_value
      end
      new_value
    end
    mapped_value || fail("Don't know how to map value '#{orig_value}' for field '#{field_name}'")
  end

  TRANSFORM_METHODS = [:mixup_css_id, :random_person_name, :invalid_ssn, :random_email, :obfuscate_sentence].freeze

  def transform_value(orig_value, field_name)
    if orig_value.is_a?(Array)
      new_array_value = []
      transforms = orig_value.map do |value|
        TRANSFORM_METHODS.find do |method|
          a_value = self.class.send(method, field_name, value)
          new_array_value << a_value if a_value
        end
      end
      [new_array_value, transforms]
    else
      new_value = nil
      # find the value of the first of TRANSFORM_METHODS that returns a non-nil value
      transform = TRANSFORM_METHODS.find { |method| new_value = self.class.send(method, field_name, orig_value) }
      [new_value, transform]
    end
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

    def invalid_ssn(field_name, field_value, fake_ssn_prefix: "000")
      # Instead of using Faker::IDNumber.invalid, make the SSN obviously fake by starting with fake_ssn_prefix
      case field_name
      when "ssn", "file_number", "veteran_file_number"
        fake_ssn_prefix + Faker::Number.number(digits: 6).to_s
      else
        case field_value
        when /^\d{9}$/
          fake_ssn_prefix + Faker::Number.number(digits: 6).to_s
        when /^\d{3}-\d{2}-\d{4}$/
          [fake_ssn_prefix, Faker::Number.number(digits: 2), Faker::Number.number(digits: 4)].join("-")
        end
      end
    end

    def random_person_name(field_name, _field_value)
      case field_name
      when "full_name", "representative_name"
        Faker::Name.name
      when "bva_poc"
        Faker::Name.name.upcase
      when "last_name"
        Faker::Name.last_name
      when "middle_name"
        Faker::Name.initials(number: 1)
      when "first_name"
        Faker::Name.first_name
      when "witness"
        witnesses = []
        rand(1..2).times do
          relationship = ["spouse", "daughter", "son", "wife", "husband",
                          "observer", "friend", "girlfriend", "brother-in-law",
                          "witness", "cousin", "stepson", "bva attorney",
                          "conservator", "daughter-in-law", "rep", "father",
                          "bva counsel"].sample
          witnesses << "#{Faker::Name.name} (#{relationship})"
        end
        witnesses.join(", ")
      when /_name$/
        Faker::Name.first_name
      end
    end

    def random_pin(field_name, field_value)
      case field_name
      when /_pin$/, /_pin_/
        if field_value is_a? String
          Faker::Number.number(digits: field_value.length).to_s
        else
          Faker::Number.number(digits: field_value.length)
        end
      end
    end

    # Keep field value recognizable but different to reduce risk of exploitation (e.g., username scraping)
    def mixup_css_id(field_name, field_value)
      case field_name
      when "css_id"
        field_value[4..-1] + field_value[0..3]
      end
    end

    def obfuscate_sentence(field_name, field_value)
      case field_name
      when "instructions", "description", "decision_text", "notes", /_text$/, /_notes$/, /_description$/
        # puts "obfuscate_sentence: #{field_name} = #{field_value}"
        field_value.split.map { |word| word[0..1] }.join(" ")
      when "military_service"
        branch = %w[ARMY AF NAVY M CG].sample
        discharge = ["Honorable", "Under Honorable Conditions"].sample
        start_date = Faker::Date.between(from: "1965-01-01", to: 10.years.ago)
        end_date = start_date + rand(1..10).years + rand(6).months + rand(15).days
        date_format = "%m/%d/%Y"
        "#{branch} #{start_date.strftime(date_format)} - #{end_date.strftime(date_format)}, #{discharge}"
      when "summary"
        <<~HTML
          <p><strong>Contentions</strong>&nbsp;</p>
          <p><span style=\"color: rgb(0,0,255);\">#{Faker::Lorem.sentence(random_words_to_add: 5)}</span></p>
          <p><strong>Evidence</strong>&nbsp;</p>
          <p><span style=\"color: rgb(0,0,255);\">#{Faker::Lorem.sentence(random_words_to_add: 5)}</span></p>
          <p><strong>Comments and special instructions to attorneys</strong>&nbsp;</p>
          <p><span style=\"color: rgb(0,0,255);\">#{Faker::Lorem.sentence(random_words_to_add: 5)}</span></p>
        HTML
      end
    end
  end
end
