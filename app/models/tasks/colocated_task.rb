# frozen_string_literal: true

##
# Any task assigned to a colocated team at the BVA, which is any team that handles admin actions at BVA.
# Colocated teams perform actions like:
#  - translating documents
#  - scheduling hearings
#  - handling FOIA requests
# Note: Full list of colocated tasks in /client/constants/CO_LOCATED_ADMIN_ACTIONS.json

class ColocatedTask < Task
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?
  validate :task_is_unique, on: :create

  after_update :update_location_in_vacols

  class << self
    def create_from_params(params, user)
      parent_task = params[:parent_id] ? Task.find(params[:parent_id]) : nil
      verify_user_can_create!(user, parent_task)
      params = modify_params_for_create(params)
      create!(params)
    end

    # Override so that each ColocatedTask for an appeal gets assigned to the same colocated staffer.
    def create_many_from_params(params_array, user)
      # Create all ColocatedTasks in one transaction so that if any fail they all fail.
      ActiveRecord::Base.multi_transaction do
        params_array = params_array.map do |params|
          # Find the task type for a given action.
          create_params = params.clone
          new_task_type = valid_type(params[:type])
          # new_task_type should be one of the valid_task_classes in tasks_controller; otherwise fail here
          create_params.merge!(type: new_task_type.name, assigned_to: new_task_type.default_assignee)
        end

        team_tasks = super(params_array, user)

        all_tasks = team_tasks.map { |team_task| [team_task, team_task.children.first] }.flatten.compact

        all_tasks.map(&:appeal).uniq.each do |appeal|
          if appeal.is_a? LegacyAppeal
            AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
          end
        end

        all_tasks
      end
    end

    def verify_user_can_create!(user, parent)
      if parent
        begin
          super(user, parent)
        rescue Caseflow::Error::ActionForbiddenError => error
          raise error unless allow_creation_exception?(user, parent)

          true
        end
      elsif !(user.attorney_in_vacols? || user.judge_in_vacols?)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
      end
    end

    # We want to allow task creation if done from attorney checkout on a vacate & de novo or during a docket switch
    def allow_creation_exception?(user, parent)
      return unless user.attorney_in_vacols?

      (parent.appeal.vacate_type == "vacate_and_de_novo") || parent.appeal.docket_switch.present?
    end

    def default_assignee
      Colocated.singleton
    end

    # Intentionally not including all descendant as we do not want to create any more of the old style
    # FoiaColocatedTasks, MissingHearingTranscriptsColocatedTasks, or TranslationColocatedTasks as their
    # PreRoutingColocatedTask versions exist only to allow tasks currently in that state in production to live
    # out their days with their old colocated task workflow
    def find_subclass_by_action(action)
      subclasses.find { |task_class| task_class.label == Constants::CO_LOCATED_ADMIN_ACTIONS[action] }
    end

    # Is this method still relevant given ticket #12279 and related tickets?
    def actions_assigned_to_colocated
      Constants::CO_LOCATED_ADMIN_ACTIONS.keys.select do |action|
        find_subclass_by_action(action).methods(false).exclude?(:default_assignee)
      end
    end

    def valid_type(type)
      unless ColocatedTask.subclasses.map(&:name).include?(type)
        fail Caseflow::Error::ActionForbiddenError, message: "Cannot create task of type #{type}"
      end

      Object.const_get(type)
    end
  end

  def timeline_title
    "#{label} completed"
  end

  def available_actions(user)
    if assigned_to == user ||
       (task_is_assigned_to_user_within_organization?(user) && Colocated.singleton.user_is_admin?(user))

      actions = [
        return_to_assigner_action,
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]

      actions.unshift(Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h) if Colocated.singleton.user_is_admin?(user)

      return actions
    end

    []
  end

  def return_to_assigner_action
    # Use assigner so that we handle creation of the ColcoatedTask from LegacyTasks gracefully.
    if JudgeTeam.for_judge(assigned_by)
      Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_JUDGE.to_h
    else
      Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h
    end
  end

  def actions_available?(_user)
    open?
  end

  def create_twin_of_type(params)
    task_type = ColocatedTask.valid_type(params[:type])
    task_type.create!(
      appeal: appeal,
      parent: parent,
      assigned_by: assigned_by,
      instructions: params[:instructions],
      assigned_to: task_type&.default_assignee
    )
  end

  private

  def create_and_auto_assign_child_task(_options = {})
    super(appeal: appeal)
  end

  def update_location_in_vacols
    if saved_change_to_status? &&
       !open? &&
       all_colocated_tasks_closed_for_appeal? &&
       appeal_in_caseflow_vacols_location? &&
       assigned_to.is_a?(Organization)
      AppealRepository.update_location!(appeal, vacols_location)
    end
  end

  def appeal_in_caseflow_vacols_location?
    return false unless appeal.is_a?(LegacyAppeal)

    return false if appeal.case_record.nil? # VACOLS case must exist

    appeal.case_record.reload.bfcurloc == LegacyAppeal::LOCATION_CODES[:caseflow]
  end

  def vacols_location
    assigned_by.vacols_uniq_id
  end

  def all_colocated_tasks_closed_for_appeal?
    appeal.tasks.open.select { |task| task.is_a?(ColocatedTask) }.none?
  end

  # Task.verify_org_task_unique already performs this check
  def verify_org_task_unique; end

  def task_is_unique
    ColocatedTask.where(
      appeal_id: appeal_id,
      assigned_to_id: assigned_to_id,
      assigned_to_type: assigned_to_type,
      type: type,
      parent_id: parent_id,
      instructions: instructions
    ).find_each do |duplicate_task|
      if duplicate_task.open?
        errors[:base] << format(
          COPY::ADD_COLOCATED_TASK_ACTION_DUPLICATE_ERROR,
          self.class.label&.upcase,
          instructions.join(", ")
        )
        break
      end
    end
  end
end

require_dependency "poa_clarification_colocated_task"
require_dependency "ihp_colocated_task"
require_dependency "hearing_clarification_colocated_task"
require_dependency "aoj_colocated_task"
require_dependency "extension_colocated_task"
require_dependency "missing_hearing_transcripts_colocated_task"
require_dependency "unaccredited_rep_colocated_task"
require_dependency "foia_colocated_task"
require_dependency "retired_vlj_colocated_task"
require_dependency "arneson_colocated_task"
require_dependency "new_rep_arguments_colocated_task"
require_dependency "pending_scanning_vbms_colocated_task"
require_dependency "address_verification_colocated_task"
require_dependency "schedule_hearing_colocated_task"
require_dependency "stayed_appeal_colocated_task"
require_dependency "missing_records_colocated_task"
require_dependency "translation_colocated_task"
require_dependency "other_colocated_task"
