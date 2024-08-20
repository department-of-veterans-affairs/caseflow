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

      # Logic to process legacy appeals and return to the board
      appeals = LegacyDocket.new.appeals_tied_to_non_ssc_avljs
      select_two_appeals_to_move(appeals)
      VACOLS::Case.batch_update_vacols_location("63", select_two_appeals_to_move.map { |appeal| appeal["bfkey"] })
      complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", appeals)

      # Filter the appeals and send the filtered report
      filtered_appeals = filter_appeals(appeals)
      send_job_slack_report(filtered_appeals)
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

  def filter_appeals(appeals, selected_appeals)
    # These are the appeals that have been moved to location '63'
    loc_63_appeals = LegacyDocket.new.loc_63_appeals

    # Number of priority and non-priority appeals moved to location '63'
    priority_appeals_moved = selected_appeals.select { |appeal| appeal["priority"] == 1 }
    non_priority_appeals_moved = selected_appeals.select { |appeal| appeal["priority"] == 0 }

    # Calculate remaining elligible appeals
    remaining_priority_appeals = appeals.select { |appeal| appeal["priority"] == 1 } - priority_appeals_moved
    remaining_non_priority_appeals = appeals.select { |appeal| appeal["priority"] == 1 } - non_priority_appeals_moved

    # List of non-SSC AVLJs that appeals were moved to location '63'
    moved_avljs = selected_appeals.map { |appeal| appeal["vlj"] }.compact.uniq

    # Keys of the hash that holds "Appeals should be grouped by non-SSC AVLJ"
    grouped_by_avlj = loc_63_appeals.group_by { |appeal| appeal["vlj"] }
      .select { |key, group| selected_appeals.map { |appeal| appeal["bfkey"] }.include?(group.first["bfkey"]) }
      .keys
      .compact

    {
      priority_appeals_count: priority_appeals_moved.size,
      non_priority_appeals_count: non_priority_appeals_moved.size,
      remaining_priority_appeals_count: remaining_priority_appeals.size,
      remaining_non_priority_appeals_count: remaining_non_priority_appeals.size,
      moved_avljs: moved_avljs,
      grouped_by_avlj: grouped_by_avlj
    }
  end

  private

  def select_two_appeals_to_move(appeals)
    appeals = appeals.sort_by { |appeal| [-appeal["priority"], appeal["bfd19"]] } unless appeals.empty?
    if appeals.count < 2
      appeals
    else
      appeals[0..1]
    end
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
