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
  validate :on_hold_duration_is_set, on: :update
  validate :task_is_unique, on: :create
  validate :valid_action_or_type

  after_update :update_location_in_vacols

  class << self
    # Override so that each ColocatedTask for an appeal gets assigned to the same colocated staffer.
    def create_many_from_params(params_array, user)
      # Create all ColocatedTasks in one transaction so that if any fail they all fail.
      ActiveRecord::Base.multi_transaction do
        params_array = params_array.map do |params|

          # Find the task type for a given action.
          input_action = params.delete(:action).to_s
          # TODO: Think of a better way to do this.
          new_task_type = ColocatedTask.subclasses.find do |task_class|
            task_class.label == Constants::CO_LOCATED_ADMIN_ACTIONS[input_action]
          end
          # TODO: Fail if there is no new_task_type.
          params.merge!(type: new_task_type.name)

          # TODO: Determine where this should be assigned shortly.
          params.merge!(assigned_to: Colocated.singleton)
        end

        team_tasks = super(params_array, user)

        all_tasks = team_tasks.map { |team_task| [team_task, team_task.children.first] }.flatten

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
        super(user, parent)
      elsif !(user.attorney_in_vacols? || user.judge_in_vacols?)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
      end
    end
  end

  def label
    action || self.class.label
  end

  def available_actions(user)
    if assigned_to == user
      base_actions = [
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]

      base_actions.push(Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h) if Colocated.singleton.user_is_admin?(user)

      return available_actions_with_conditions(base_actions)
    end

    if task_is_assigned_to_user_within_organization?(user) && Colocated.singleton.admins.include?(user)
      return [Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h]
    end

    []
  end

  def available_actions_with_conditions(core_actions)
    if %w[translation schedule_hearing].include?(action) && appeal.is_a?(LegacyAppeal)
      return legacy_translation_or_hearing_actions(core_actions)
    end

    core_actions.unshift(Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h)
    core_actions.unshift(Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h)

    if action == "translation" && appeal.is_a?(Appeal)
      return ama_translation_actions(core_actions)
    end

    core_actions
  end

  def actions_available?(_user)
    open?
  end

  def create_twin_of_type(params)
    self.class.create!(
      appeal: appeal,
      parent: parent,
      assigned_by: assigned_by,
      action: params[:action],
      instructions: params[:instructions],
      assigned_to: Colocated.singleton
    )
  end

  private

  def ama_translation_actions(core_actions)
    core_actions.push(Constants.TASK_ACTIONS.SEND_TO_TRANSLATION.to_h)
    core_actions
  end

  def legacy_translation_or_hearing_actions(actions)
    return legacy_schedule_hearing_actions(actions) if action == "schedule_hearing"

    legacy_translation_actions(actions)
  end

  def legacy_schedule_hearing_actions(actions)
    task_actions = Constants.TASK_ACTIONS
    actions = actions.reject { |action| action[:label] == task_actions.ASSIGN_TO_PRIVACY_TEAM.to_h[:label] }
    actions.unshift(task_actions.SCHEDULE_HEARING_SEND_TO_TEAM.to_h)
    actions
  end

  def legacy_translation_actions(actions)
    send_to_team = Constants.TASK_ACTIONS.SEND_TO_TEAM.to_h
    send_to_team[:label] = format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, Constants::CO_LOCATED_ADMIN_ACTIONS[action])
    actions.unshift(send_to_team)
  end

  def create_and_auto_assign_child_task(_options = {})
    super(appeal: appeal)
  end

  def update_location_in_vacols
    if saved_change_to_status? &&
       !open? &&
       all_tasks_closed_for_appeal? &&
       appeal_in_caseflow_vacols_location? &&
       assigned_to.is_a?(Organization)
      AppealRepository.update_location!(appeal, location_based_on_action)
    end
  end

  def appeal_in_caseflow_vacols_location?
    appeal.is_a?(LegacyAppeal) &&
      VACOLS::Case.find(appeal.vacols_id).bfcurloc == LegacyAppeal::LOCATION_CODES[:caseflow]
  end

  def location_based_on_action
    case action.to_sym
    when :schedule_hearing
      # Return to attorney if the task is cancelled. For instance, if the VLJ support staff sees that the hearing was
      # actually held.
      return assigned_by.vacols_uniq_id if children.all? { |t| t.status == Constants.TASK_STATUSES.cancelled }

      # Schedule hearing with a task (instead of changing Location in VACOLS, the old way)
      ScheduleHearingTask.create!(appeal: appeal, parent: appeal.root_task)

      LegacyAppeal::LOCATION_CODES[:caseflow]
    when :translation
      LegacyAppeal::LOCATION_CODES[action.to_sym]
    else
      assigned_by.vacols_uniq_id
    end
  end

  def all_tasks_closed_for_appeal?
    appeal.tasks.open.where(type: ColocatedTask.name).none?
  end

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && assigned_to.is_a?(User)
      errors.add(:on_hold_duration, "has to be specified")
    end
  end

  def task_is_unique
    ColocatedTask.where(
      appeal_id: appeal_id,
      assigned_to_id: assigned_to_id,
      assigned_to_type: assigned_to_type,
      action: action,
      parent_id: parent_id,
      instructions: instructions
    ).find_each do |duplicate_task|
      if duplicate_task.open?
        errors[:base] << format(
          COPY::ADD_COLOCATED_TASK_ACTION_DUPLICATE_ERROR,
          Constants::CO_LOCATED_ADMIN_ACTIONS[action]&.upcase,
          instructions.join(", ")
        )
        break
      end
    end

    def valid_action_or_type
      unless Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s).include?(action) || ColocatedTask.subclasses.include?(self.class)
        errors[:base] << "invalid action (#{action}) or type (#{type})"
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
require_dependency "missing_records_colocated_task"
require_dependency "translation_colocated_task"
require_dependency "other_colocated_task"
