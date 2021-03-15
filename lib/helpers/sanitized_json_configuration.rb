# frozen_string_literal: true

class SanitizedJsonConfiguration

  # To-do: load this from a file or automatically determine fields to sanitize
  SANITIZE_FIELDS ||= {
    Appeal => %w[veteran_file_number],
    AppealIntake => %w[veteran_file_number],
    Veteran => %w[first_name last_name middle_name file_number ssn],
    Claimant => %w[],
    User => %w[full_name email css_id],
    Person => %w[date_of_birth email_address first_name last_name middle_name ssn],
    Task => %w[instructions],
    # cavc_judge_full_name is selected from Constants::CAVC_JUDGE_FULL_NAMES; no need to sanitize
    CavcRemand => %w[instructions],
    Organization => %w[],
    TaskTimer => %w[],
    OrganizationsUser => %w[],
    RequestDecisionIssue => %w[],
    RequestIssue => ["notes", /_(notes|text|description)/],
    DecisionIssue => %w[description decision_text],
    HearingTaskAssociation => %w[],
    Hearing => %w[notes military_service summary bva_poc representative_name witness],
    HearingDay => %w[bva_poc notes],
    VirtualHearing => %w[alias guest_pin host_pin guest_pin_long host_pin_long representative_email
                         judge_email alias_with_host appellant_email host_hearing_link guest_hearing_link]
  }.freeze

  # https://stackoverflow.com/questions/13355549/rails-activerecord-detect-if-a-column-is-an-association-or-not
  class AssocationWrapper
    attr_reader :associations

    def initialize(clazz)
      @associations = clazz.reflect_on_all_associations
    end

    def belongs_to
      @associations = @associations.select { |assoc| assoc.macro == :belongs_to }
      self
    end

    def without_type_field
      # TODO: handle assoc.foreign_key.is_a?(Symbol)
      @associations = @associations.select { |assoc| assoc.foreign_type.nil? && assoc.foreign_key.is_a?(String) }
      self
    end

    def has_type_field
      @associations = @associations.select(&:foreign_type)
      self
    end

    def associated_with_type(assoc_class)
      @associations = @associations.select { |assoc| assoc.class_name == assoc_class.name }
      self
    end

    def ignore_fieldnames(ignore_fieldnames)
      @associations = @associations.reject { |assoc| ignore_fieldnames&.include?(assoc.foreign_key) } if ignore_fieldnames.any?
      self
    end

    def fieldnames
      @associations.map(&:foreign_key)
    end
  end

  def self.fieldnames_of_typed_associations_with(assoc_class, clazz)
    AssocationWrapper.new(clazz).belongs_to.associated_with_type(assoc_class).fieldnames.presence
  end

  def self.fieldnames_of_untyped_associations_with(assoc_class, clazz)
    AssocationWrapper.new(clazz).belongs_to.without_type_field.associated_with_type(assoc_class).fieldnames.presence
  end

  def self.fieldnames_of_typed_associations_for(clazz, ignore_fieldnames)
    AssocationWrapper.new(clazz).belongs_to.has_type_field.ignore_fieldnames(ignore_fieldnames).fieldnames.presence
  end

  def self.grouped_fieldnames_of_typed_associations_with(clazz, known_classes)
    AssocationWrapper.new(clazz).belongs_to.associations
      .group_by(&:class_name)
      .slice(*known_classes)
      .transform_values { |assocs| assocs.map(&:foreign_key) }
      .compact
  end

  # Special types that can be have `same_unique_attributes?`
  # or where we want to look up its id, e.g. Appeal for Claimant used in `same_unique_attributes?`
  ID_MAPPING_TYPES = [Appeal, User, Person, Organization].freeze

  # types that we need to examine for associations and update them
  REASSOCIATE_TYPES = [DecisionReview, AppealIntake, Veteran, Claimant, Task, TaskTimer, CavcRemand,
                       DecisionIssue, RequestIssue, RequestDecisionIssue,
                       Hearing, HearingTaskAssociation, HearingDay, VirtualHearing,
                       OrganizationsUser].freeze

  # in case a Class is associated with a specific decendant of one of the REASSOCIATE_TYPES
  REASSOCIATE_TYPES_DESCENDANTS = REASSOCIATE_TYPES.map(&:descendants).flatten
  KNOWN_TYPES = (REASSOCIATE_TYPES + REASSOCIATE_TYPES_DESCENDANTS).uniq # - (ID_MAPPING_TYPES - [Appeal])
  KNOWN_TYPE_NAMES = KNOWN_TYPES.map(&:name)

  # To-do: load this from a file or automatically determine fields to sanitize
  # modelClass => fieldnames_array
  OFFSET_ID_FIELDS ||= REASSOCIATE_TYPES.map do |clazz|
    [clazz, grouped_fieldnames_of_typed_associations_with(clazz, KNOWN_TYPE_NAMES).values.flatten]
  end.to_h.tap do |class_to_fieldnames_hash|
    # array of decision_issue_ids; not declared as an association in Rails, so add it manually
    class_to_fieldnames_hash[CavcRemand] << "decision_issue_ids"  

    # TODO: Why is :participant_id listed as a association? Why is it a symbol whereas others are strings?
    class_to_fieldnames_hash[Claimant].delete(:participant_id) 
  end.compact.freeze

  # For all the REASSOCIATE_TYPES, identify there associations so the '_id' fields can be updated based on imported records
  # TODO: consider using KNOWN_TYPES instead of REASSOCIATE_TYPES, or consolidating e.g. TranscriptionTask => ["assigned_to_id", "appeal_id"] with that of Task
  REASSOCIATE_FIELDS ||= {
    # These untyped association fields will associate to the User ActiveRecord
    "User" => REASSOCIATE_TYPES.map { |clazz| [clazz, fieldnames_of_untyped_associations_with(User, clazz)] }.to_h.compact,

    # These typed polymorphic association fields will associate to the their corresponding ActiveRecord
    :type => REASSOCIATE_TYPES.map { |clazz| [clazz, fieldnames_of_typed_associations_for(clazz, OFFSET_ID_FIELDS[clazz])] }.to_h.compact
  }.freeze

  # ==========  Exporter Configuration ==============

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
  class << self

    def records_to_export(initial_appeals)
      associated_appeals = initial_appeals.map { |appeal| appeals_associated_with(appeal) }.flatten.uniq.compact
      appeals = (initial_appeals + associated_appeals).uniq
      tasks = appeals.map(&:tasks).flatten.sort_by(&:id).extend(TaskAssignment)
      cavc_remands = appeals.map(&:cavc_remand).compact
      hearings = tasks.with_type("HearingTask").map(&:hearing).uniq.compact
      hearing_days = hearings.map(&:hearing_day).uniq.compact

      request_issues = appeals.map(&:request_issues).flatten
      export_records = {
        Appeal => appeals,
        AppealIntake => appeals.map(&:intake),
        Veteran => appeals.map(&:veteran),
        Claimant => appeals.map(&:claimants).flatten,
        Task => tasks,
        TaskTimer => TaskTimer.where(task_id: tasks.map(&:id)),
        CavcRemand => cavc_remands,
        DecisionIssue => appeals.map(&:decision_issues).flatten,
        RequestIssue => request_issues,
        RequestDecisionIssue => RequestDecisionIssue.where(request_issue: request_issues),
        Hearing => hearings,
        HearingTaskAssociation => HearingTaskAssociation.where(hearing: hearings),
        HearingDay => hearing_days,
        VirtualHearing => hearings.map(&:virtual_hearing).uniq.compact
      }

      users = tasks.map(&:assigned_by).compact + tasks.map(&:cancelled_by).compact +
              tasks.assigned_to_user.map(&:assigned_to) +
              cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten.uniq.compact +
              appeals.map(&:intake).compact.map(&:user).uniq.compact +
              hearing_days.map { |hd| [hd.created_by, hd.updated_by, hd.judge] }.flatten.uniq.compact +
              hearings.map { |h| [h.created_by, h.updated_by, h.judge] }.flatten.uniq.compact +
              hearings.map(&:virtual_hearing).uniq.compact
                .map { |vh| [vh.created_by, vh.updated_by] }.flatten.uniq.compact
      export_records.merge!(
        User => users,
        Organization => tasks.assigned_to_org.map(&:assigned_to) + users.map(&:organizations).flatten.uniq,
        OrganizationsUser => OrganizationsUser.where(user: users),
        Person => (export_records[Veteran] + export_records[Claimant]).map(&:person).uniq.compact
      )
    end

    def appeals_associated_with(appeal)
      appeal.cavc_remand&.source_appeal
      # To-do: include other source appeals, e.g., those with the same docket number
    end

    def before_sanitize_hook(record, obj_hash)
      case record
      when User
        # User#attributes includes `display_name`; don't need it when importing so leave it out
        obj_hash.delete(:display_name)
      end  
    end

    # To-do: generate the automatically
    TRANSFORM_METHODS = [:mixup_css_id, :random_person_name, :invalid_ssn, :random_email, :obfuscate_sentence, :similar_date, :random_pin].freeze

    def transform_methods
      TRANSFORM_METHODS
    end

    # :reek:RepeatedConditionals
    def random_email(field_name, field_value)
      case field_name
      when "email_address", /email$/
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

    def similar_date(field_name, field_value)
      case field_name
      when "date_of_birth"
        case field_value
        when Date
          Faker::Date.between_except(from: field_value - 1.year, to: field_value, excepted: field_value)
        when /^\d{4}-\d{2}-\d{2}$/
          Faker::Date.between_except(from: Date.parse(field_value) - 1.year, to: field_value, excepted: field_value).to_json
        end
      end
    end

    def random_pin(field_name, field_value)
      case field_name
      when /_pin$/, /_pin_/
        if field_value.is_a?(String)
          Faker::Number.number(digits: field_value.length).to_s
        else
          Faker::Number.number(digits: field_value.to_s.length)
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

  # ==========  Importer Configuration ==============

  # Classes that shouldn't be imported if a record with the same unique attributes already exists
  NONDUPLICATE_TYPES = [Organization, User, Veteran, Person].freeze

  # During record creation, types where validation and callbacks should be avoided
  TYPES_THAT_SKIP_VALIDATION_AND_CALLBACKS = [Task, *Task.descendants].freeze

  # Start with important types that other records will reassociate with
  FIRST_TYPES_TO_IMPORT = [Appeal, User, Organization, HearingDay]

  class << self
    def check_first_imports(imported_records)
      fail "Warning: No appeal imported, aborting import of remaining records" if imported_records[Appeal.table_name].blank?
    end

    # :reek:FeatureEnvy
    def same_unique_attributes?(existing_record, obj_hash, importer: nil)
      case existing_record
      when Organization
        existing_record.url == obj_hash["url"]
      when User
        existing_record.css_id == obj_hash["css_id"]
      when Claimant
        # check if claimant is associated with appeal we just imported
        imported_appeal_id = importer.id_mapping[Appeal.name][obj_hash["decision_review_id"]]
        existing_record.decision_review_id == imported_appeal_id
      when Person
        # To-do: Person.connection.index_exists? :people, :participant_id
        # To-do: ActiveRecord::Base.connection.indexes(Person.table_name).select{|idx| idx.unique}
        existing_record.participant_id == obj_hash["participant_id"]
      end
    end

    def create_singleton(clazz, obj_hash, obj_description)
      # Handle Organization type specially because each organization has a `singleton`
      # To-do: update dev's seed data to match prod's Organization#singleton record ids
      if clazz == Organization && !org_already_exists?(obj_hash)
        puts "  + Creating #{clazz} '#{obj_hash['name']}' with its original id #{obj_hash['id']} \n\t#{obj_description}"
        return clazz.create!(obj_hash)
      end
    end
    
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

    def before_creation_hook(clazz, obj_hash, obj_description, importer: nil)
      puts "  + Creating #{clazz} #{obj_hash['id']} \n\t#{obj_description}"
      remaining_id_fields = obj_hash.select do |field_name, field_value|
        field_name.ends_with?("_id") && field_value.is_a?(Integer) && (field_value < importer.id_offset) &&
          (
            !(clazz <= Task && field_name == "assigned_to_id" && obj_hash["assigned_to_type"] == "Organization") &&
            !(clazz <= OrganizationsUser && field_name == "organization_id")
            # !(clazz <= OrganizationsUser && field_name == "user_id")
          )
      end
      fail "!! For #{clazz}, expecting these *'_id' fields be adjusted: #{remaining_id_fields}\n\tobj_hash: #{obj_hash}" unless remaining_id_fields.blank?
    end
  end
end
