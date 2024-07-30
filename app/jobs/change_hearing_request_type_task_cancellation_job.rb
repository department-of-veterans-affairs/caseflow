# frozen_string_literal: true

# Public: Async job that will be ran by an AWS CRON job that will close all open Change Hearing Request Type Tasks
#              on legacy appeals. The Change Hearing request Type Taks is being considered to be removed by the business
#              and they want all open CHRT tasks closed for the time being. This job will need ot be removed once the
#              task is remopved from the prod

# :nocov:
class ChangeHearingRequestTypeTaskCancellationJob < CaseflowJob
  queue_with_priority :low_priority

  # Desciption: Method to run the logic of the job
  #
  # Params: None
  # Returns: nil
  def perform
    RequestStore[:current_user] = User.system_user
    begin
      close_open_change_hearing_request_type_tasks(open_change_hearing_request_type_tasks)
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
    ChangeHearingRequestTypeTask.open.includes(:legacy_appeal)
  end

  # Description: Loops through the open ChangeHearingRequestTypeTaks from open_change_hearing_request_type_tasks
  # and will envoke the ChnageHearingRequestTypeTask update_by_params method
  #    which will not only cancel the ChangeHearingRequestTypeTaks but also the paranet HearingTask
  #
  # Params: none
  # Returns: nil
  def close_open_change_hearing_request_type_tasks(tasks)
    Rails.logger.info("Attempting to remediate " +
                  open_change_hearing_request_type_tasks.count.to_s +
                  " Change Hearing Request Type Tasks")

    tasks.each do |task|
      begin
        location = task&.appeal&.location_code.to_s
        vacols_id = task&.appeal&.vacols_id.to_s
        Rails.logger.info("Closing CHRT on Legacy Appeal: " +
                      vacols_id.to_s +
                      " at location " +
                      location.to_s)
        task&.update_from_params({ "status": "cancelled", "instructions": "" }, User.system_user)
        Rails.logger.info("Appeal:" + vacols_id + "CHRT closed")
      rescue StandardError => error
        Rails.logger.info("Task: " + task.id.to_s + "Failed top be remdiated")
        log_error(error)
        next
      end
    end
  end
end
# :nocov:
