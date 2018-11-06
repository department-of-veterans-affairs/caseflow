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

    def modify_params(params)
      params["type"] = Constants.CO_LOCATED_CLASS_FOR_ACTION[params.delete("label")]
      super
    end

    private

    def list_of_assignees
      Constants::CoLocatedTeams::USERS[Rails.current_env]
    end
  end

  def label
    Constants.CO_LOCATED_CLASS_FOR_ACTION.to_h.to_a.reverse.to_h[type]
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
      AppealRepository.update_location!(appeal, location)
    end
  end

  def location
    assigned_by.vacols_uniq_id
  end

  def all_tasks_completed_for_appeal?
    appeal.tasks.where(type: ColocatedTask.name).map(&:status).uniq == [Constants.TASK_STATUSES.completed]
  end

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end
end

class IhpColocatedTask < ColocatedTask; end

class PoaClarificationColocatedTask < ColocatedTask; end

class HearingClarificationColocatedTask < ColocatedTask; end

class AojColocatedTask < ColocatedTask; end

class ExtensionColocatedTask < ColocatedTask; end

class MissingHearingTranscriptsColocatedTask < ColocatedTask; end

class UnaccreditedRepColocatedTask < ColocatedTask; end

class FoiaColocatedTask < ColocatedTask; end

class RetiredVljColocatedTask < ColocatedTask; end

class ArnesonColocatedTask < ColocatedTask; end

class NewRepArgumentsColocatedTask < ColocatedTask; end

class PendingScanningVbmsColocatedTask < ColocatedTask; end

class AddressVerificationColocatedTask < ColocatedTask; end

class MissingRecordsColocatedTask < ColocatedTask; end

class OtherColocatedTask < ColocatedTask; end

class MovableColocatedTask < ColocatedTask
  def available_actions(user)
    if appeal.class.eql?(LegacyAppeal)
      return [
        {
          label: COPY::COLOCATED_ACTION_PLACE_HOLD,
          value: Constants::CO_LOCATED_ACTIONS["PLACE_HOLD"]
        },
        {
          label: format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, label),
          value: "modal/send_colocated_task"
        }
      ]
    end

    super
  end
end

class ScheduleHearingColocatedTask < MovableColocatedTask
  def location
    "57"
  end
end

class TranslationColocatedTask < MovableColocatedTask
  def location
    "14"
  end
end
