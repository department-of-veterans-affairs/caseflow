class ColocatedTask < Task
  include RoundRobinAssigner

  validate :assigned_by_role_is_valid
  validates :assigned_by, presence: true
  validates :parent, presence: true, if: :ama?

  after_update :update_location_in_vacols

  class << self
    # Override so that each ColocatedTask for an appeal gets assigned to the same colocated staffer.
    def create_many_from_params(params_array, _)
      create(params_array.map { |p| modify_params(p) })
    end

    def create(tasks)
      ActiveRecord::Base.multi_transaction do
        assignee = next_assignee
        records = [tasks].flatten.each_with_object([]) do |task, result|
          result << super(task.merge(assigned_to: assignee))
          result
        end
        if records.map(&:valid?).uniq == [true] && records.first.legacy?
          AppealRepository.update_location!(records.first.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        end
        records
      end
    end

    private

    def list_of_assignees
      Constants::CoLocatedTeams::USERS[Rails.current_env]
    end
  end

  def available_actions(_user)
    [
      {
        label: COPY::COLOCATED_ACTION_PLACE_HOLD,
        value: Constants::CO_LOCATED_ACTIONS["PLACE_HOLD"]
      },
      {
        label: COPY::COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY,
        value: "modal/mark_task_complete"
      }
    ]
  end

  def no_actions_available?(user)
    !user.colocated_in_vacols? || completed?
  end

  def update_if_hold_expired!
    update!(status: Constants.TASK_STATUSES.in_progress) if on_hold_expired?
  end

  def on_hold_expired?
    return true if placed_on_hold_at && on_hold_duration && placed_on_hold_at + on_hold_duration.days < Time.zone.now
    false
  end

  private

  def update_location_in_vacols
    if saved_change_to_status? &&
       completed? &&
       appeal_type == LegacyAppeal.name &&
       all_tasks_completed_for_appeal?
      AppealRepository.update_location!(appeal, location_based_on_action)
    end
  end

  def location_based_on_action
    assigned_by.vacols_uniq_id
  end

  def all_tasks_completed_for_appeal?
    appeal.tasks.where(type: ColocatedTask.name).map(&:status).uniq == [Constants.TASK_STATUSES.completed]
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end
end

class MovableColocatedTask < ColocatedTask
  def available_actions(user)
    actions = super(user)

    # Expect the first action to be the mark task complete action which we want to replace with the task-specific
    # relocation logic.
    if appeal.class.eql?(LegacyAppeal)
      actions[0] = {
        label: format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, action),
        value: "modal/send_colocated_task"
      }
    end

    actions
  end
end

# TODO: I think we only use the "action" field for populating the "type" column in the case table view. Perhaps we can
# just map from task type directly to what text we want to display in that column on the frontend itself?
class ScheduleHearingColocatedTask < MovableColocatedTask
  def action
    "Schedule hearing"
  end

  def location_based_on_action
    "57"
  end
end

class TranslationColocatedTask < MovableColocatedTask
  def action
    "Translation"
  end

  def location_based_on_action
    "14"
  end
end

class IhpColocatedTask < ColocatedTask
  def action
    "IHP"
  end
end

class PoaClarificationColocatedTask < ColocatedTask
  def action
    "POA clarification"
  end
end

class HearingClarificationColocatedTask < ColocatedTask
  def action
    "Hearing clarification"
  end
end

class AojColocatedTask < ColocatedTask
  def action
    "AOJ"
  end
end

class ExtensionColocatedTask < ColocatedTask
  def action
    "Extension"
  end
end

class MissingHearingTranscriptsColocatedTask < ColocatedTask
  def action
    "Missing hearing transcripts"
  end
end

class UnaccreditedRepColocatedTask < ColocatedTask
  def action
    "Unaccredited rep"
  end
end

class FoiaColocatedTask < ColocatedTask
  def action
    "FOIA"
  end
end

class RetiredVljColocatedTask < ColocatedTask
  def action
    "Retired VLJ"
  end
end

class ArnesonColocatedTask < ColocatedTask
  def action
    "Arneson"
  end
end

class NewRepArgumentsColocatedTask < ColocatedTask
  def action
    "New rep arguments"
  end
end

class PendingScanningVbmsColocatedTask < ColocatedTask
  def action
    "Pending scanning (VBMS)"
  end
end

class AddressVerificationColocatedTask < ColocatedTask
  def action
    "Address verification"
  end
end

class MissingRecordsColocatedTask < ColocatedTask
  def action
    "Missing records"
  end
end

class OtherColocatedTask < ColocatedTask
  def action
    "Other"
  end
end
