# frozen_string_literal: true

# Public: Async job that will be ran by an AWS CRON job that will close all open Change Hearing Request Type Tasks
#              on legacy appeals. The Change Hearing request Type Taks is being considered to be removed by the business
#              and they want all open CHRT tasks closed for the time being. This job will need ot be removed once the
#              task is remopved from the prod

# :nocov:
class ChangeHearingRequestTypeTaskJobCancellationJob < CaseflowJob
  queue_with_priority :low_priority

  # Desciption: Method to run the logic of the job
  #
  # Params: None
  # Returns: nil
  def perform
    RequestStore[:current_user] = User.system_user
    begin
      close_open_change_hearing_request_type_tasks!
    rescue StandardError => error
      log_error(error)
    end
  end

  private

  # Description: Gathers a list of all open ChangeHearingRequestTypesTasks
  #
  # Params: None
  # Returns: ActiveRecord::Relation of ChangeHearingRequestTypeTasks
  def open_change_hearing_request_type_tasks
    @open_change_hearing_request_type_tasks ||= ChangeHearingRequestTypeTask.open.includes(:legacy_appeal)
  end

  # Description: Loops through teh open ChangeHearingRequestTypeTaks from open_change_hearing_request_type_tasks
  # if the appeal is active will check if there is an on hold ScheduleHearingTask sibling ith the same HearingTask parent
  #    and activate the ScheduleHearingTask and cancell the ChangeHearingRequestTypeTask
  # if the appeal is closed will envoke the ChnageHearingRequestTypeTask update_by_params method
  #    which will not only cancel the ChangeHearingRequestTypeTaks but also the paranet HearingTask
  #
  # Params: none
  # Returns: nil
  def close_open_change_hearing_request_type_tasks!
    return if open_change_hearing_request_type_tasks.empty?

    open_change_hearing_request_type_tasks.each do |task|
      if task&.appeal&.active?
        if task&.ancestor_task_of_type(ScheduleHearingTask)&.on_hold?
          on_hold_sibling_schedule_hearing_task = task&.ancestor_task_of_type(ScheduleHearingTask)
          on_hold_sibling_schedule_hearing_task&.assigned!
          task.cancelled!
        end
      else
        task&.update_from_params({ "status": "cancelled", "instructions": "" }, User.system_user)
      end
    end
  end
end
# :nocov:
