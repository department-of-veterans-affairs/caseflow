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

      eligible_and_moved_appeals(appeals, selected_appeals)

      complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", selected_appeals)

      # Filter the appeals and send the filtered report
      @filtered_appeals = filter_appeals(appeals, selected_appeals)
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

  def filter_appeals(appeals, selected_appeals)
    # Separate priority and non-priority appeals
    priority_appeals_moved, non_priority_appeals_moved = separate_by_priority(selected_appeals)

    remaining_priority_appeals,
    remaining_non_priority_appeals = calculate_remaining_appeals(
      appeals,
      priority_appeals_moved,
      non_priority_appeals_moved
    )

    # List of non-SSC AVLJs that appeals were moved to location '63'
    moved_avljs = fetch_moved_avljs(selected_appeals)

    # Keys of the hash that holds "Appeals should be grouped by non-SSC AVLJ" for moved appeals
    grouped_by_avlj = (
      selected_appeals.group_by { |appeal| VACOLS::Staff.find_by(sattyid: appeal["vlj"])&.sattyid }
    ).keys.compact

    {
      priority_appeals_count: priority_appeals_moved.size,
      non_priority_appeals_count: non_priority_appeals_moved.size,
      remaining_priority_appeals_count: remaining_priority_appeals.size,
      remaining_non_priority_appeals_count: remaining_non_priority_appeals.size,
      moved_avljs: moved_avljs,
      grouped_by_avlj: grouped_by_avlj
    }
  end

  def eligible_and_moved_appeals
    appeals = LegacyDocket.new.appeals_tied_to_non_ssc_avljs
    selected_appeals = move_qualifying_appeals(LegacyDocket.new.appeals_tied_to_non_ssc_avljs)
    [appeals, selected_appeals]
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

    qualifying_appeals
  end

  def non_ssc_avljs
    VACOLS::Staff.where("sactive = 'A' AND svlj = 'A' AND sattyid <> smemgrp")
  end

  # Method to separate appeals by priority
  def separate_by_priority(appeals)
    priority_appeals = appeals.select { |appeal| appeal["priority"] == 1 }
    non_priority_appeals = appeals.select { |appeal| appeal["priority"] == 0 }
    [priority_appeals, non_priority_appeals]
  end

  # Method to calculate remaining eligible appeals
  def calculate_remaining_appeals(all_appeals, moved_priority_appeals, moved_non_priority_appeals)
    remaining_priority_appeals = (
      all_appeals.select { |appeal| appeal["priority"] == 1 } -
      moved_priority_appeals
    )
    remaining_non_priority_appeals = (
      all_appeals.select { |appeal| appeal["priority"] == 0 } -
      moved_non_priority_appeals
    )
    [remaining_priority_appeals, remaining_non_priority_appeals]
  end

  # Method to fetch non-SSC AVLJs that appeals were moved to location '63'
  def fetch_moved_avljs(selected_appeals)
    selected_appeals.map { |appeal| VACOLS::Staff.find_by(sattyid: appeal["vlj"]) }
      .compact
      .uniq
      .map { |record| get_name_from_record(record) }
  end

  def get_name_from_record(record)
    FullName.new(record["snamef"], nil, record["snamel"]).to_s
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
    report << "Priority Appeals Moved: #{@filtered_appeals[:priority_appeals_count]}"
    report << "Non-Priority Appeals Moved: #{@filtered_appeals[:non_priority_appeals_count]}"
    report << "Remaining Priority Appeals: #{@filtered_appeals[:remaining_priority_appeals_count]}"
    report << "Remaining Non-Priority Appeals: #{@filtered_appeals[:remaining_non_priority_appeals_count]}"
    report << "Moved AVLJs: #{@filtered_appeals[:moved_avljs].join(', ')}"
    report << "Grouped by AVLJ: #{@filtered_appeals[:grouped_by_avlj].join(', ')}"
    report
  end
end
