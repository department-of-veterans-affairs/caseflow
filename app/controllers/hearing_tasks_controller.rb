# frozen_string_literal: true

class HearingTasksController < TasksController
  def schedule
    scheduler.schedule(hearing_params)

    update
  end

  def withdraw
    workflow.withdraw!

    update
  end

  def hold
    workflow.hold!

    update
  end

  def cancel
    workflow.cancel!

    update
  end

  def no_show
    workflow.no_show!

    update
  end

  def postpone
    workflow.postpone!

    update
  end

  def postpone_and_reschedule
    workflow.postpone!(should_reschedule_later: false)

    scheduler.reschedule(hearing_params)

    update
  end

  def postpone_and_reschedule_later_with_admin_action
    workflow.postpone!(should_reschedule_later: false)

    scheduler.reschedule_later_with_admin_action(reschedule_later_params)

    update
  end

  def hearing_task
    return task if task.is_a? HearingTask

    task.parent
  end

  def workflow
    Hearings::WorkflowManager.new(hearing_task)
  end

  def scheduler
    Hearings::Scheduler.new(appeal, hearing_task: hearing_task)
  end

  def hearing_params
    params.require(:hearing).permit(
      :hearing_day_id, :hearing_location_attrs, :scheduled_time_string,
      :override_full_hearing_day_validation
    )
  end

  def reschedule_later_params
    params.require(:reschedule_later).permit(
      :instructions, :admin_action_klas, :admin_action_instructions
    )
  end
end
