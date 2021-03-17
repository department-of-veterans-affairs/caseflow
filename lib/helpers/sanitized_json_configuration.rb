# frozen_string_literal: true

require "helpers/association_wrapper.rb"
require "helpers/sanitation_transforms.rb"

# Configuration for exporting/importing data from/to Caseflow.

class SanitizedJsonConfiguration
  # For exporting, the :retrieval lambda is run according to the ordering in this hash.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def configuration
    @configuration ||= {
      Appeal => {
        track_imported_ids: true,
        sanitize_fields: %w[veteran_file_number],
        retrieval: lambda do |records|
          initial_appeals = records[Appeal]
          (initial_appeals +
          initial_appeals.map { |appeal| self.class.appeals_associated_with(appeal) }.flatten.uniq.compact
          ).uniq
        end
      },
      Veteran => {
        track_imported_ids: true,
        sanitize_fields: %w[file_number first_name last_name middle_name ssn],
        retrieval: ->(records) { records[Appeal].map(&:veteran) }
      },
      AppealIntake => {
        sanitize_fields: %w[veteran_file_number],
        retrieval: ->(records) { records[Appeal].map(&:intake) }
      },
      Claimant => {
        retrieval: ->(records) { records[Appeal].map(&:claimants).flatten }
      },
      Task => {
        sanitize_fields: %w[instructions],
        retrieval: ->(records) { records[Appeal].map(&:tasks).flatten.sort_by(&:id).extend(TaskAssignment) }
      },
      TaskTimer => {
        retrieval: ->(records) { TaskTimer.where(task_id: records[Task].map(&:id)) }
      },
      RequestIssue => {
        sanitize_fields: ["notes", "contested_issue_description", /_(notes|text|description)/],
        retrieval: ->(records) { records[Appeal].map(&:request_issues).flatten }
      },
      DecisionIssue => {
        sanitize_fields: %w[decision_text description],
        retrieval: ->(records) { records[Appeal].map(&:decision_issues).flatten }
      },
      RequestDecisionIssue => {
        retrieval: ->(records) { RequestDecisionIssue.where(request_issue: records[RequestIssue]) }
      },
      CavcRemand => { # dependent on DecisionIssue records
        # cavc_judge_full_name is selected from Constants::CAVC_JUDGE_FULL_NAMES; no need to sanitize
        sanitize_fields: %w[instructions],
        retrieval: ->(records) { records[Appeal].map(&:cavc_remand).compact }
      },
      Hearing => {
        sanitize_fields: %w[bva_poc military_service notes representative_name summary witness],
        retrieval: lambda do |records|
          (records[Appeal].map(&:hearings) + records[Task].with_type("HearingTask").map(&:hearing)).flatten.uniq.compact
        end
      },
      HearingDay => {
        sanitize_fields: %w[bva_poc notes],
        retrieval: ->(records) { records[Hearing].map(&:hearing_day).uniq.compact }
      },
      VirtualHearing => {
        sanitize_fields: %w[alias alias_with_host appellant_email conference_id guest_hearing_link guest_pin
                            guest_pin_long host_hearing_link host_pin host_pin_long judge_email representative_email],
        retrieval: ->(records) { records[Hearing].map(&:virtual_hearing).uniq.compact }
      },
      HearingTaskAssociation => {
        retrieval: ->(records) { HearingTaskAssociation.where(hearing: records[Hearing]) }
      },

      User => {
        track_imported_ids: true,
        sanitize_fields: %w[css_id email full_name],
        retrieval: lambda do |records|
          tasks = records[Task]
          cavc_remands = records[CavcRemand]
          hearings = records[Hearing]

          tasks.map(&:assigned_by).compact + tasks.map(&:cancelled_by).compact +
            tasks.assigned_to_user.map(&:assigned_to) +
            cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten.uniq.compact +
            records[Appeal].map(&:intake).compact.map(&:user).uniq.compact +
            records[AppealIntake].map { |intake| intake&.user }.uniq.compact +
            records[HearingDay].map { |hday| [hday.created_by, hday.updated_by, hday.judge] }.flatten.uniq.compact +
            hearings.map { |hearing| [hearing.created_by, hearing.updated_by, hearing.judge] }.flatten.uniq.compact +
            hearings.map(&:virtual_hearing).uniq.compact.map do |vh|
              [vh.created_by, vh.updated_by]
            end.flatten.uniq.compact
        end
      },
      Organization => {
        track_imported_ids: true,
        retrieval: lambda do |records|
          records[Task].assigned_to_org.map(&:assigned_to) + records[User].map(&:organizations).flatten.uniq
        end
      },
      OrganizationsUser => {
        retrieval: ->(records) { OrganizationsUser.where(user: records[User]) }
      },
      Person => {
        track_imported_ids: true,
        sanitize_fields: %w[date_of_birth email_address first_name last_name middle_name ssn],
        retrieval: ->(records) { (records[Veteran] + records[Claimant]).map(&:person).uniq.compact }
      }
    }.freeze
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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

  private

  def extract_configuration(config_field, configuration, default_value = nil)
    configuration.select { |clazz, _| clazz < ActiveRecord::Base }
      .map { |clazz, class_config| [clazz, class_config[config_field] || default_value.clone] }.to_h.compact
  end

  def extract_classes_with_true(config_field, configuration)
    configuration.select { |_, config| config[config_field] == true }.keys.compact
  end

  # Types that need to be examine for associations so that '_id' fields can be updated by id_offset
  # exclude id_mapping_types because we are reassociating those ourselves (don't try to id_offset them)
  def reassociate_types
    # DecisionReview is parent class of Appeal, HLR, SC. We want associations of Appeal to be reassociated.
    @reassociate_types ||= (configuration.keys - id_mapping_types + [DecisionReview]).uniq
  end

  public

  # Special types that can have `same_unique_attributes?`
  # or where we want to look up its id, e.g. Appeal for Claimant used in `same_unique_attributes?`
  # The id are tracked in `importer.id_mapping` and are used by reassociate_with_imported_records
  def id_mapping_types
    @id_mapping_types = extract_classes_with_true(:track_imported_ids, configuration).freeze
  end

  # Fields that will be offset by the id_offset when imported
  # rubocop:disable Style/MultilineBlockChain
  def offset_id_fields
    @offset_id_fields ||= begin
      # In case a Class is associated with a specific decendant of one of the reassociate_types, include descendants.
      # Exclude id_mapping_types since they will be handled by reassociate_with_imported_records via reassociate_fields
      known_types = (reassociate_types + reassociate_types.map(&:descendants).flatten - id_mapping_types).uniq

      reassociate_types.map do |clazz|
        [
          clazz,
          AssocationWrapper.grouped_fieldnames_of_typed_associations_with(clazz, known_types.map(&:name))
            .values.flatten.sort
        ]
      end.to_h.tap do |class_to_fieldnames_hash|
        # array of decision_issue_ids; not declared as an association in Rails, so add it manually
        class_to_fieldnames_hash[CavcRemand].push("decision_issue_ids").sort!

        # Why is :participant_id listed as a association? Why is it a symbol whereas others are strings?
        class_to_fieldnames_hash[Claimant].delete(:participant_id)
      end.compact.freeze
    end
  end
  # rubocop:enable Style/MultilineBlockChain

  # ==========  Exporter Configuration ==============
  def sanitize_fields_hash
    @sanitize_fields_hash ||= extract_configuration(:sanitize_fields, configuration, []).freeze
  end

  def records_to_export(initial_appeals)
    export_records = {
      Appeal => initial_appeals
    }

    # incrementally update export_records as subsequent calls may rely on prior updates to export_records
    extract_configuration(:retrieval, configuration).map do |clazz, retrieval_lambda|
      export_records[clazz] = retrieval_lambda.call(export_records)
    end

    export_records
  end

  def self.appeals_associated_with(appeal)
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

  # Fields whose mapped value should not be saved to the @value_mapping hash,
  # e.g., due to distinct orig_values mapping to the same new_value
  MAPPED_VALUES_IGNORED_FIELDS = %w[first_name middle_name last_name].freeze
  MAPPED_VALUES_IGNORED_TRANSFORMS = [:random_pin, :obfuscate_sentence, :similar_date].freeze

  # :reek:LongParameterList
  def save_mapped_value?(transform_method, field_name, _orig_value, _new_value)
    !(MAPPED_VALUES_IGNORED_TRANSFORMS.include?(transform_method) ||
      MAPPED_VALUES_IGNORED_FIELDS.include?(field_name))
  end

  def transform_methods
    @transform_methods ||= SanitizationTransforms.instance_methods
  end

  include SanitizationTransforms

  # ==========  Importer Configuration ==============
  attr_writer :id_offset

  def id_offset
    @id_offset ||= 2_000_000_000
  end

  # Start with important types that other records will reassociate with
  def first_types_to_import
    # HearingDay is needed by Hearing
    @first_types_to_import ||= [Appeal, Organization, User, HearingDay].freeze
  end

  # During record creation, types where validation and callbacks should be avoided
  def types_that_skip_validation_and_callbacks
    @types_that_skip_validation_and_callbacks ||= [Task, *Task.descendants, Hearing].freeze
  end

  # Classes that shouldn't be imported if a record with the same unique attributes already exists
  # These types should be handled in `find_existing_record`.
  def nonduplicate_types
    # Adding OrganizationsUser because we don't want to create duplicate OrganizationsUser records
    @nonduplicate_types ||= id_mapping_types + [OrganizationsUser].freeze
    # binding.pry if id_mapping_types != @nonduplicate_types
    @nonduplicate_types
  end

  # For each class in nonduplicate_types, provide a way to find the existing record
  def find_existing_record(clazz, obj_hash, importer: nil)
    if clazz == User
      User.find_by_css_id(obj_hash["css_id"]) # cannot
    elsif clazz == OrganizationsUser
      user_id = importer.id_mapping[User.name][obj_hash["user_id"]]
      organization_id = importer.id_mapping[Organization.name][obj_hash["organization_id"]]
      OrganizationsUser.find_by(user_id: user_id, organization_id: organization_id)
    elsif clazz == Appeal
      Appeal.find_by(uuid: obj_hash["uuid"]) # cannot; TODO: allow class to provide find_by_uniq_field
    elsif [Organization, Veteran, Person].include?(clazz)
      # Let importer find it using the fallback: clazz.find_by(unique_field: obj_hash[unique_field])
      nil
    end
  end

  USE_PROD_ORGANIZATION_IDS = false

  def create_singleton(clazz, obj_hash, obj_description: obj_description)
    new_label = adjust_identifiers_for_unique_records(clazz, obj_hash)
    if new_label
      puts "  * Will import duplicate #{clazz} '#{new_label}' with different unique attributes " \
            "because existing record's id is different: \n\t#{obj_hash}"
      # binding.pry
    end

    # Only needed if we want Organizations to have same record id's as in prod.
    # Handle Organization type specially because each organization has a `singleton`
    # To-do: update dev's seed data to match prod's Organization#singleton record ids
    if USE_PROD_ORGANIZATION_IDS && clazz == Organization && !self.class.org_already_exists?(obj_hash)
      puts "  + Creating #{clazz} '#{obj_hash['name']}' with its original id #{obj_hash['id']} \n\t#{obj_description}"
      clazz.create!(obj_hash)
    end
  end

  def self.org_already_exists?(obj_hash)
    Organization.find_by(url: obj_hash["url"]) || Organization.find_by(id: obj_hash["id"])
  end

  # :reek:FeatureEnvy
  def adjust_identifiers_for_unique_records(clazz, obj_hash)
    if clazz <= Organization
      obj_hash["url"] += "_imported" if Organization.find_by(url: obj_hash["url"])
    elsif clazz <= User
      # Change CSS_ID if it already exists for a user with different user.id
      obj_hash["css_id"] += "_imported" if User.find_by_css_id(obj_hash["css_id"])
    end
  end

  def reassociate_fields
    # For each reassociate_types, identify their associations so '_id' fields can be updated to imported records
    # TODO: shouldn't all id_mapping_types be a key in this hash?
    @reassociate_fields ||= {
      # Typed polymorphic association fields will associate to the their corresponding ActiveRecord
      :type => reassociate_types.map do |clazz|
        [clazz, AssocationWrapper.fieldnames_of_typed_associations_for(clazz, offset_id_fields[clazz])]
      end.to_h.compact
    }.merge(
      # Untyped association fields (those without the matching '_type' field) will associate to User records
      id_mapping_types.map { |assoc_class| [
        assoc_class.name,
        reassociate_types.map do |clazz|
          [clazz, AssocationWrapper.fieldnames_of_untyped_associations_with(assoc_class, clazz)]
        end.to_h.compact
      ]}.to_h
    ).freeze
  end

  # :reek:LongParameterList
  # :reek:UnusedParameters
  # rubocop:disable Lint/UnusedMethodArgument, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def before_creation_hook(clazz, obj_hash, obj_description: nil, importer: nil)
    remaining_id_fields = obj_hash.select do |field_name, field_value|
      field_name.ends_with?("_id") && field_value.is_a?(Integer) && (field_value < id_offset) &&
        (
          !(clazz <= Task && field_name == "assigned_to_id" && obj_hash["assigned_to_type"] == "Organization") &&
          !(clazz <= OrganizationsUser && (field_name == "organization_id" || field_name == "user_id")) &&
          # !(clazz <= HearingDay && field_name == "judge_id") &&
          !(clazz <= VirtualHearing && field_name == "conference_id") &&
          true
        )
    end
    unless remaining_id_fields.blank?
      binding.pry
      fail "!! For #{clazz}, expecting these *'_id' fields be adjusted: " \
           "#{remaining_id_fields}\n\tobj_hash: #{obj_hash}"
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # ==========  Difference Configuration ==============
  def expected_differences
    @expected_differences ||= {
      User => [:display_name],
    }.freeze
  end
end
