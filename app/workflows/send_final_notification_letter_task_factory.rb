# frozen_string_literal: true

class SendFinalNotificationLetterTaskFactory
  def initialize(task)
    @task = task
  end

  def create_send_final_notification_letter_tasks
    Task.transaction do
      sfnlt = SendFinalNotificationLetterTask.create!(
        appeal: @task.appeal,
        parent: @task.parent,
        assigned_to: Organization.find_by_url("clerk-of-the-board"),
        assigned_by: current_user
      )
      # sfnlt.instructions.push(instructions)
      sfnlt.update!(status: Constants.TASK_STATUSES.assigned)
    end
  end
end
