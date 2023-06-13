# frozen_string_literal: true

class HearingPostponementRequestMailTask < HearingRequestMailTask
  class << self
    # These should live in COPY.json
    def label
      "Hearing postponement request"
    end

    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(_user)
    TASK_ACTIONS
  end

  def update_from_params(params, current_user)
    if params[:status] == Constants.TASK_STATUSES.completed
      multi_transaction do
        update!(
          status: Constants.TASK_STATUSES.completed,
          completed_by: current_user
        )

        cancel_existing_hearing_tasks!(current_user)

        create_new_root_hearing_task!
      end
    end
  end

  private

  # Cancels HearingTasks and HearingPostponementRequestMailTasks
  def cancel_existing_hearing_tasks!(current_user)
    # How would this need to change for legacy appeals?
    appeal.tasks.active.each do |task|
      next unless [HearingTask.name, name].include?(task.type)

      task.update!(
        status: Constants.TASK_STATUSES.cancelled,
        cancelled_by: current_user
      )
    end
  end

  # Kind of just guessing here and putting the new HearingTask
  # under the same parent of the most recent HearingTask in the tree.
  #
  #
  def create_new_root_hearing_task!
    most_recent_hearing_task = locate_most_recent_hearing_task

    if most_recent_hearing_task
      HearingTask.create!(
        appeal: appeal,
        parent: most_recent_hearing_task.parent,
        assigned_to: Bva.singleton
      )
    end
  end

  def locate_most_recent_hearing_task
    appeal.tasks.where(type: HearingTask.name).order(created_at: :desc).first
  end
end
