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

      appeals = LegacyDocket.new.appeals_tied_to_non_ssc_avljs
      moved_appeals = move_qualifying_appeals(appeals)
      complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", moved_appeals)
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
    qualifying_appeals_bfkeys = []

    non_ssc_avljs.each do |non_ssc_avlj|
      tied_appeals = appeals.select { |appeal| appeal["vlj"] == non_ssc_avlj.sattyid }
      tied_appeals_bfkeys = get_tied_appeal_bfkeys(tied_appeals)
      qualifying_appeals_bfkeys = update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)
    end

    unless qualifying_appeals_bfkeys.empty?
      qualifying_appeals = appeals
        .select { |q_appeal| qualifying_appeals_bfkeys.include? q_appeal["bfkey"] }
        .flatten
        .sort_by { |appeal| [-appeal["priority"], appeal["bfd19"]] }
      VACOLS::Case.batch_update_vacols_location("63", qualifying_appeals.map { |q_appeal| q_appeal["bfkey"] })
    end

    qualifying_appeals
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

  def get_tied_appeal_bfkeys(tied_appeals)
    tied_appeals_bfkeys = []

    unless tied_appeals.empty?
      tied_appeals_bfkeys = tied_appeals
        .sort_by { |t_appeal| [-t_appeal["priority"], t_appeal["bfd19"]] }
        .map { |t_appeal| t_appeal["bfkey"] }
        .uniq
        .flatten
    end

    tied_appeals_bfkeys
  end

  def update_qualifying_appeals_bfkeys(tied_appeals_bfkeys, qualifying_appeals_bfkeys)
    if tied_appeals_bfkeys.any?
      if tied_appeals_bfkeys.count < 2
        qualifying_appeals_bfkeys.push(tied_appeals_bfkeys)
      else
        qualifying_appeals_bfkeys.push(tied_appeals_bfkeys[0..1])
      end
    end

    qualifying_appeals_bfkeys.flatten
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
