# frozen_string_literal: true

class HearingTasksController < TasksController
  def schedule_veteran
    # TASK_ACTIONS.SCHEDULE_VETERAN
    hearing_task.multi_transaction do
      workflow.scheduler.schedule(hearing_params.to_h.symbolize_keys)
      update
    end
  end

  def reschedule_no_show_hearing
    # TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING
    hearing_task.multi_transaction do
      workflow.scheduler.rechedule_later(instructions: params[:instructions])
      update
    end
  end

  def create_change_hearing_disposition_task
    # TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK
    # TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK
    hearing_task.multi_transaction do
      workflow.disposition.admin_changes_needed_after_hearing_date(instructions: params[:instructions])
      update
    end
  end

  def withdraw_hearing
    # TASK_ACTIONS.WITHDRAW_HEARING
    hearing_task.multi_transaction do
      workflow.withdraw!
      update
    end
  end

  def hold
    # TASK_ACTIONS.CHANGE_HEARING_DISPOSITION
    hearing_task.multi_transaction do
      workflow.dispostion.hold!
      update
    end
  end

  def cancel
    # TASK_ACTIONS.CHANGE_HEARING_DISPOSITION
    hearing_task.multi_transaction do
      workflow.disposition.cancel!
      update
    end
  end

  def no_show
    # TASK_ACTIONS.CHANGE_HEARING_DISPOSITION
    hearing_task.multi_transaction do
      workflow.disposition.no_show!
      update
    end
  end

  def postpone_and_reschedule
    # TASK_ACTIONS.CHANGE_HEARING_DISPOSITION
    # TASK_ACTIONS.POSTPONE_HEARING
    hearing_task.multi_transaction do
      workflow.disposition.postpone_and_reschedule!(hearing_params.to_h.symbolize_keys)
      update
    end
  end

  def postpone_and_reschedule_later
    # TASK_ACTIONS.CHANGE_HEARING_DISPOSITION
    # TASK_ACTIONS.POSTPONE_HEARING
    hearing_task.multi_transaction do
      workflow.disposition.postpone_and_reschedule_later!(
        instructions: params[:instructions],
        admin_action_attributes: admin_action_params.to_h.symbolize_keys
      )
      update
    end
  end

  private

  def hearing_task
    @hearing_task ||= if task.is_a? HearingTask
                        task
                      else
                        task.parent
                      end
  end

  def workflow
    Hearings::WorkflowManager.new(hearing_task)
  end

  def update_params
    # for testing, flag to circumvent update from params method
    super.merge(disable_update_from_params: true)
  end

  def hearing_params
    params.require(:hearing).permit(
      :hearing_day_id, :hearing_location_attrs, :scheduled_time_string,
      :override_full_hearing_day_validation
    )
  end

  def admin_action_params
    if params.key?(:admin_action_attributes)
      params[:admin_action_attributes]
        .permit(:admin_action_klass, :admin_action_instructions)
    end
  end
end
