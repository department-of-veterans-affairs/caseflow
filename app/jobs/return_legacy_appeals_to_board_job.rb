# frozen_string_literal: true

class ReturnLegacyAppealsToBoardJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  # include RunAsyncable

  queue_as :low_priority
  application_attr :queue

  def perform
    begin
      returned_appeal_job = create_returned_appeal_job
      # Here add logic to process legacy appeals and return them to the board goes here
      complete_returned_appeal_job(returned_appeal_job, "Job completed successfully")
      send_job_slack_report
    rescue StandardError => error
      errored_returned_appeal_job(returned_appeal_job, "Job failed with error: #{error.message}")
      start_time ||= Time.zone.now # temporary fix to get this job to succeed
      duration = time_ago_in_words(start_time)
      slack_msg = "<!here>\n [ERROR] after running for #{duration}: #{error.message}"
      slack_service.send_notification(slack_msg, self.class.name)
      log_error(error)
    ensure
      @start_time ||= Time.zone.now
      metrics_service_report_runtime(metric_group_name: "return_legacy_appeals_to_board_job")
    end
  end

  private

  def create_returned_appeal_job
    ReturnedAppealJob.create!(
      started_at: Time.zone.now,
      stats: { message: "Job started" }.to_json
    )
  end

  def complete_returned_appeal_job(returned_appeal_job, message)
    returned_appeal_job.update!(
      completed_at: Time.zone.now,
      stats: { message: message }.to_json
    )
  end

  def errored_returned_appeal_job(returned_appeal_job, message)
    returned_appeal_job.update!(
      errored_at: Time.zone.now,
      stats: { message: message }.to_json
    )
  end

  def send_job_slack_report
    slack_service.send_notification(slack_report.join("\n"), self.class.name)
  end

  def slack_report
    report = []
    report << "Job performed successfully"
    report
  end
end
