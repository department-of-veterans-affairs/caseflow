# frozen_string_literal: true

class ReturnLegacyAppealsToBoardJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  # include RunAsyncable

  queue_as :low_priority
  application_attr :queue

  def perform
    begin
      returned_appeal_job = ReturnedAppealJob.create!(start: Time.zone.now, stats: { message: "Job started" }.to_json)
      # Here add logic to process legacy appeals and return them to the board goes here
      returned_appeal_job.update!(end: Time.zone.now, stats: { message: "Job completed successfully" }.to_json)
      send_job_report
    rescue StandardError => error
      returned_appeal_job.update!(errored: Time.zone.now, stats: {
        message: "Job failed with error: #{error.message}"
      }.to_json)
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

  def send_job_report
    slack_service.send_notification(slack_report.join("\n"), self.class.name)
  end

  def slack_report
    report = []
    report << "Job performed successfully"
    report
  end
end
