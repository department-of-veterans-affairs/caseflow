# frozen_string_literal: true

require "helpers/association_wrapper.rb"
require "helpers/sanitation_transforms.rb"

# Configuration for exporting/importing data from/to Caseflow's database.
# Needed by SanitizedJsonExporter and SanitizedJsonImporter.

class SanitizedJsonConfiguration
  # For exporting, the :retrieval lambda is run according to the ordering in this hash.
  # Results of running each lambda are added to the `records` hash for use by later retrieval lambdas.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def configuration
    @configuration ||= {
      Appeal => {
        # Need track_imported_ids=true because parent DecisionReview is abstract,
        # i.e., DecisionReview has no table_name and hence cannot be used
        # when reassociating using polymorphic associations.
        track_imported_ids: true,
        sanitize_fields: %w[veteran_file_number],
        retrieval: lambda do |records|
          (records[Appeal] +
            records[Appeal].map { |appeal| self.class.appeals_associated_with(appeal) }.flatten.uniq.compact
          ).uniq.sort_by(&:id)
        end
      },
      Veteran => {
        track_imported_ids: true,
        sanitize_fields: %w[file_number first_name last_name middle_name ssn],
        retrieval: ->(records) { records[Appeal].map(&:veteran).sort_by(&:id) }
      },
      AppealIntake => {
        sanitize_fields: %w[veteran_file_number],
        retrieval: ->(records) { records[Appeal].map(&:intake).compact.sort_by(&:id) }
      },
      DecisionDocument => {
        # citation_number must be unique and doesn't reference anything else in Caseflow,
        # so transform the number so we can import into the same DB as the original record
        sanitize_fields: %w[citation_number],
        retrieval: ->(records) { DecisionDocument.where(appeal: records[Appeal]).order(:id) }
      },
      Claimant => {
        retrieval: ->(records) { records[Appeal].map(&:claimants).flatten.sort_by(&:id) }
      },
      Task => {
        sanitize_fields: %w[instructions],
        retrieval: ->(records) { reorder_for_import(Task.where(appeal: records[Appeal])) }
      },
      TaskTimer => {
        retrieval: ->(records) { TaskTimer.where(task_id: records[Task].map(&:id)).order(:id) }
      },
      JudgeCaseReview => {
        sanitize_fields: %w[comment],
        retrieval: ->(records) { JudgeCaseReview.where(task_id: records[Task].map(&:id)).order(:id) }
      },
      AttorneyCaseReview => {
        retrieval: ->(records) { AttorneyCaseReview.where(task_id: records[Task].map(&:id)).order(:id) }
      },
      DecisionIssue => {
        # In order to import DecisionIssues before RequestIssues (since RequestIssue records refer to DecisionIssue),
        # export DecisionIssue records first.
        sanitize_fields: %w[decision_text description],
        retrieval: lambda do |records|
          appeal_decision_issue_ids = records[Appeal].map(&:decision_issues).flatten.map(&:id)
          request_issues = records[Appeal].map(&:request_issues).flatten
          other_decision_issues_ids = request_issues.compact.map(&:contested_decision_issue).compact.map(&:id)

          DecisionIssue.where(id: appeal_decision_issue_ids + other_decision_issues_ids).order(:id)
        end
      },
      RequestIssue => {
        sanitize_fields: ["notes", "contested_issue_description", /_(notes|text|description)/],
        retrieval: ->(records) { records[Appeal].map(&:request_issues).flatten.sort_by(&:id) }
      },
      RequestDecisionIssue => {
        retrieval: ->(records) { RequestDecisionIssue.where(request_issue: records[RequestIssue]).order(:id) }
      },
      CavcRemand => { # dependent on DecisionIssue records
        # cavc_judge_full_name is selected from Constants::CAVC_JUDGE_FULL_NAMES; no need to sanitize
        sanitize_fields: %w[instructions],
        retrieval: ->(records) { records[Appeal].map(&:cavc_remand).compact.sort_by(&:id) }
      },
      Hearing => {
        sanitize_fields: %w[bva_poc military_service notes representative_name summary witness],
        retrieval: lambda do |records|
          (records[Appeal].map(&:hearings) +
            Task.where(id: records[Task].map(&:id), type: :HearingTask).map(&:hearing)
          ).flatten.uniq.compact.sort_by(&:id)
        end
      },
      HearingDay => {
        sanitize_fields: %w[bva_poc notes],
        retrieval: ->(records) { records[Hearing].map(&:hearing_day).uniq.compact.sort_by(&:id) }
      },
      VirtualHearing => {
        sanitize_fields: %w[alias alias_with_host appellant_email conference_id guest_hearing_link guest_pin
                            guest_pin_long host_hearing_link host_pin host_pin_long judge_email representative_email],
        retrieval: ->(records) { records[Hearing].map(&:virtual_hearing).uniq.compact.sort_by(&:id) }
      },
      HearingTaskAssociation => {
        retrieval: ->(records) { HearingTaskAssociation.where(hearing: records[Hearing]).order(:id) }
      },

      User => {
        track_imported_ids: true,
        sanitize_fields: %w[css_id email full_name],
        retrieval: lambda do |records|
          # eager load task associations
          tasks = Task.where(id: records[Task].map(&:id)).includes(:assigned_by, :assigned_to, :cancelled_by)
          cavc_remands = records[CavcRemand]
          hearings = records[Hearing]

          users = tasks.map(&:assigned_by).compact + tasks.map(&:cancelled_by).compact +
                  tasks.assigned_to_any_user.map(&:assigned_to) +
                  cavc_remands.map { |cavc_remand| [cavc_remand.created_by, cavc_remand.updated_by] }.flatten +
                  records[Appeal].map(&:intake).compact.map(&:user) +
                  records[AppealIntake].map { |intake| intake&.user } +
                  records[HearingDay].map { |hday| [hday.created_by, hday.updated_by, hday.judge] }.flatten +
                  hearings.map { |hearing| [hearing.created_by, hearing.updated_by, hearing.judge] }.flatten +
                  hearings.map(&:virtual_hearing).uniq.compact.map { |vh| [vh.created_by, vh.updated_by] }.flatten

          users.uniq.compact.sort_by(&:id)
        end
      },
      OrganizationsUser => {
        retrieval: ->(records) { OrganizationsUser.where(user: records[User]) }
      },
      Organization => {
        track_imported_ids: true,
        retrieval: lambda do |records|
          # eager load task associations
          org_tasks = Task.where(id: records[Task].map(&:id)).includes(:assigned_to).assigned_to_any_org
          org_ids = records[OrganizationsUser].map(&:organization_id) + org_tasks.map(&:assigned_to_id)
          # Use Organization.unscoped to include inactive organizations when exporting
          Organization.unscoped.where(id: org_ids).order(:id)
        end
      },
      Person => {
        track_imported_ids: true,
        sanitize_fields: %w[date_of_birth email_address first_name last_name middle_name ssn],
        retrieval: ->(records) { (records[Veteran] + records[Claimant]).map(&:person).uniq.compact }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def reorder_for_import(tasks)
    tasks = tasks.sort_by(&:id)
    reordered_tasks = tasks.select { |task| task.parent_id.nil? }
    tasks -= reordered_tasks
    while tasks.any?
      task_ids = reordered_tasks.pluck("id")
      child_tasks = tasks.select { |task| task_ids.include?(task.parent_id) }
      fail "Tasks with unknown parent task still remain" if child_tasks.blank?

      reordered_tasks += child_tasks
      tasks -= child_tasks
    end
    reordered_tasks
  end

  def extract_configuration(config_field, configuration, default_value = nil)
    configuration.select { |klass, _| klass < ActiveRecord::Base }
      .map { |klass, class_config| [klass, class_config[config_field] || default_value.clone] }.to_h.compact
  end

  def extract_classes_with_true(config_field, configuration)
    configuration.select { |_, config| config[config_field] == true }.keys.compact
  end

  # Types that need to be examine for associations so that '_id' fields can be updated by id_offset
  # exclude id_mapping_types because we are reassociating those using id_mapping (don't try to id_offset them)
  def reassociate_types
    # DecisionReview is parent class of Appeal, HLR, SC. We want associations to Appeals to be reassociated.
    @reassociate_types ||= (configuration.keys - id_mapping_types + [DecisionReview]).uniq
  end

  public

  # Types whose id's are tracked in `importer.id_mapping` and are used by `reassociate_with_imported_records`
  # or where we want to look up its new id
  def id_mapping_types
    @id_mapping_types ||= extract_classes_with_true(:track_imported_ids, configuration)
  end

  # Fields that will be offset by the id_offset when imported
  # rubocop:disable Style/MultilineBlockChain
  def offset_id_fields
    @offset_id_fields ||= begin
      # In case a Class is associated with a specific decendant of one of the reassociate_types, include descendants.
      # Exclude id_mapping_types since they will be handled by reassociate_with_imported_records via reassociate_fields
      known_types = (reassociate_types + reassociate_types.map(&:descendants).flatten - id_mapping_types).uniq

      reassociate_types.map do |klass|
        [
          klass,
          AssocationWrapper.new(klass).grouped_fieldnames_of_typed_associations_with(known_types.map(&:name))
            .values.flatten.sort
        ]
      end.to_h.tap do |class_to_fieldnames_hash|
        # array of decision_issue_ids; not declared as an association in Rails, so add it manually
        class_to_fieldnames_hash[CavcRemand].push("decision_issue_ids").sort!

        # Why is :participant_id listed as a association? Why is it a symbol whereas others are strings?
        class_to_fieldnames_hash[Claimant].delete(:participant_id)
      end.compact
    end
  end
  # rubocop:enable Style/MultilineBlockChain

  # ==========  SanitizedJsonExporter-specific Configuration ==============
  def sanitize_fields_hash
    @sanitize_fields_hash ||= extract_configuration(:sanitize_fields, configuration, [])
  end

  def records_to_export(initial_appeals)
    export_records = {
      Appeal => initial_appeals
    }

    # This is just a reminder for how we can handle legacy appeals, i.e. by using :legacy_retrieval.
    # Currently no :legacy_retrieval lambdas have been defined.
    retrieval_key = initial_appeals.first.is_a?(LegacyAppeal) ? :legacy_retrieval : :retrieval
    # incrementally update export_records as subsequent calls may rely on prior updates to export_records
    extract_configuration(retrieval_key, configuration).map do |klass, retrieval_lambda|
      export_records[klass] = retrieval_lambda.call(export_records)
    end

    export_records
  end

  def self.appeals_associated_with(appeal)
    # To-do: include other source appeals, e.g., those with the same docket number
    [
      appeal.cavc_remand&.source_appeal,
      appeal.appellant_substitution&.source_appeal,
      appeal.request_issues.map { |rqi| rqi.contested_decision_issue&.decision_review }
    ].flatten.compact
  end

  def before_sanitize(record, obj_hash)
    case record
    when User
      # User#attributes includes `display_name`; don't need it when importing so leave it out
      obj_hash.delete(:display_name)
    end
  end

  # Fields whose mapped value should not be saved to the @value_mapping hash,
  # e.g., due to distinct orig_values mapping to the same new_value
  MAPPED_VALUES_IGNORED_FIELDS ||= %w[first_name middle_name last_name].freeze
  MAPPED_VALUES_IGNORED_TRANSFORMS ||= [:random_pin, :obfuscate_sentence, :similar_date].freeze

  # :reek:LongParameterList
  def save_mapped_value?(transform_method, field_name, _orig_value, _new_value)
    !(MAPPED_VALUES_IGNORED_TRANSFORMS.include?(transform_method) ||
      MAPPED_VALUES_IGNORED_FIELDS.include?(field_name))
  end

  def transform_methods
    @transform_methods ||= SanitizationTransforms.instance_methods
  end

  include SanitizationTransforms

  # ==========  SanitizedJsonImporter-specific Configuration ==============
  attr_writer :id_offset

  def id_offset
    @id_offset ||= 2_000_000_000
  end

  # Start with important types that other records will reassociate with.
  # Then import according to the order in the Json file
  def first_types_to_import
    # HearingDay is needed by Hearing
    @first_types_to_import ||= [Appeal, Organization, User, HearingDay, Task]
  end

  # During record creation, types where validation and callbacks should be avoided
  def types_that_skip_validation_and_callbacks
    @types_that_skip_validation_and_callbacks ||= [Task, *Task.descendants, Hearing, CavcRemand]
  end

  # Classes that shouldn't be imported if a record with the same unique attributes already exists
  # These types should be handled in `find_existing_record`.
  def reuse_record_types
    # Adding OrganizationsUser because we don't want to create duplicate OrganizationsUser records
    @reuse_record_types ||= id_mapping_types + [OrganizationsUser]
  end

  # For each class in reuse_record_types, provide a way to find the existing record
  # :reek:UnusedParameters
  # rubocop:disable Lint/UnusedMethodArgument
  def find_existing_record(klass, obj_hash, importer: nil)
    if klass == User
      # The index for css_id has an odd column name plus find_by_css_id is faster.
      User.find_by_css_id(obj_hash["css_id"])
    elsif klass == Appeal
      # uuid is not a uniq index, so can't rely on importer to do it automatically
      Appeal.find_by(uuid: obj_hash["uuid"])
    elsif [Organization, Veteran, Person].include?(klass)
      # Let importer find it using the fallback: klass.find_by(unique_field: obj_hash[unique_field])
      nil
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument

  USE_PROD_ORGANIZATION_IDS ||= false

  def reassociate_fields
    # For each reassociate_types, identify their associations so '_id' fields can be reassociated with imported records
    @reassociate_fields ||= {
      # Typed polymorphic association fields will be associated based on the '_type' field
      type: reassociate_types.map do |klass|
        [klass,
         AssocationWrapper.new(klass).typed_associations(excluding: offset_id_fields[klass]).fieldnames.presence]
      end.to_h.compact
    }.merge(
      # Untyped association fields (ie, without the matching '_type' field) will associate to their corresponding type
      id_mapping_types.map do |assoc_class|
        [
          assoc_class.name,
          reassociate_types.map do |klass|
            [klass,
             AssocationWrapper.new(klass).untyped_associations_with(assoc_class).fieldnames.presence]
          end.to_h.compact
        ]
      end .to_h
    )
  end

  # :reek:LongParameterList
  # :reek:UnusedParameters
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/UnusedMethodArgument
  def before_creation_hook(klass, obj_hash, obj_description: nil, importer: nil)
    # Basic check to make sure *`_id` fields have been updated
    remaining_id_fields = obj_hash.select do |field_name, field_value|
      field_name.ends_with?("_id") && field_value.is_a?(Integer) && (field_value < id_offset) &&
        (
          !(klass <= Task && field_name == "assigned_to_id" && obj_hash["assigned_to_type"] == "Organization") &&
          !(klass <= OrganizationsUser && (field_name == "organization_id" || field_name == "user_id")) &&
          !(klass <= VirtualHearing && field_name == "conference_id") &&
          !(klass <= RequestIssue && field_name == "vacols_sequence_id") # Handle this when we can export VACOLS data
        )
    end
    unless remaining_id_fields.blank?
      puts "!! For #{klass}, expecting these *'_id' fields be adjusted: " \
           "#{remaining_id_fields}\n\tobj_hash: #{obj_hash}"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/UnusedMethodArgument

  # ==========  SanitizedJsonDifference-specific Configuration ==============
  def expected_differences
    @expected_differences ||= {
      User => [:display_name]
    }
  end
end
