# frozen_string_literal: true

class ReturnLegacyAppealsToBoardJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  # include RunAsyncable

  queue_as :low_priority
  application_attr :queue

  def perform(fail_job = false)
    begin
      returned_appeal_job = create_returned_appeal_job
      fail if fail_job

      move_qualifying_appeals(LegacyDocket.new.appeals_tied_to_non_ssc_avljs)
      complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", appeals)
      send_job_slack_report
    rescue StandardError => error
      message = "Job failed with error: #{error.message}"
      errored_returned_appeal_job(returned_appeal_job, message)
      start_time ||= Time.zone.now # temporary fix to get this job to succeed
      duration = time_ago_in_words(start_time)
      slack_msg = "<!here>\n [ERROR] after running for #{duration}: #{error.message}"
      slack_service.send_notification(slack_msg, self.class.name)
      log_error(error)
      message
    ensure
      @start_time ||= Time.zone.now
      metrics_service_report_runtime(metric_group_name: "return_legacy_appeals_to_board_job")
    end
  end

  private

  def move_qualifying_appeals(appeals)
    qualifying_appeals = []

    non_ssc_avljs.each do |non_ssc_avlj|
      tied_appeals = appeals.select { |appeal| appeal["vlj"] == non_ssc_avlj.sattyid }

      unless tied_appeals.empty?
        tied_appeals = tied_appeals.sort_by { |t_appeal| [-t_appeal["priority"], t_appeal["bfd19"]] }
      end

      if appeals.count < 2
        qualifying_appeals.push(tied_appeals).flatten
      else
        qualifying_appeals.push(tied_appeals[0..1]).flatten
      end
    end

    unless qualifying_appeals.empty?
      qualifying_appeals = qualifying_appeals
        .flatten
        .sort_by { |appeal| [-appeal["priority"], appeal["bfd19"]] }
    end

    VACOLS::Case.batch_update_vacols_location("63", qualifying_appeals.map { |q_appeal| q_appeal["bfkey"] })
  end

  def non_ssc_avljs
    VACOLS::Staff.where("sactive = 'A' AND svlj = 'A' AND sattyid <> smemgrp")
  end

  def create_returned_appeal_job
    ReturnedAppealJob.create!(
      started_at: Time.zone.now,
      stats: { message: "Job started" }.to_json
    )
  end

  def complete_returned_appeal_job(returned_appeal_job, message, appeals)
    returned_appeal_job.update!(
      completed_at: Time.zone.now,
      stats: { message: message }.to_json,
      returned_appeals: appeals.map { |appeal| appeal["bfkey"] }
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
