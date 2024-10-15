# frozen_string_literal: true

class ReturnLegacyAppealsToBoardJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :queue

  NO_RECORDS_FOUND_MESSAGE = [Constants.DISTRIBUTION.no_records_moved_message].freeze

  def perform
    catch(:abort) do
      begin
        returned_appeal_job = create_returned_appeal_job

        appeals, moved_appeals = eligible_and_moved_appeals

        check_appeals_available(moved_appeals, returned_appeal_job)

        complete_returned_appeal_job(returned_appeal_job, "Job completed successfully", moved_appeals)

        # The rest of your code continues here
        # Filter the appeals and send the filtered report
        @filtered_appeals = filter_appeals(appeals, moved_appeals)
        send_job_slack_report(slack_report)
      rescue StandardError => error
        handle_error(error, returned_appeal_job)
      ensure
        metrics_service_report_runtime(metric_group_name: "return_legacy_appeals_to_board_job")
      end
    end
  end

  def filter_appeals(appeals, moved_appeals)
    priority_appeals_moved, non_priority_appeals_moved = separate_by_priority(moved_appeals)

    remaining_priority_appeals,
    remaining_non_priority_appeals = calculate_remaining_appeals(
      appeals,
      priority_appeals_moved,
      non_priority_appeals_moved
    )

    {
      priority_appeals_count: count_unique_bfkeys(priority_appeals_moved),
      non_priority_appeals_count: count_unique_bfkeys(non_priority_appeals_moved),
      remaining_priority_appeals_count: count_unique_bfkeys(remaining_priority_appeals),
      remaining_non_priority_appeals_count: count_unique_bfkeys(remaining_non_priority_appeals),
      grouped_by_avlj: grouped_by_avlj(moved_appeals)
    }
  end

  def eligible_and_moved_appeals
    appeals = LegacyDocket.new.appeals_tied_to_non_ssc_avljs
    moved_appeals = move_qualifying_appeals(appeals)
    [appeals, moved_appeals]
  end

  def grouped_by_avlj(moved_appeals)
    return [] if moved_appeals.nil?

    moved_appeals.group_by { |appeal| VACOLS::Staff.find_by(sattyid: appeal["vlj"])&.sattyid }.keys.compact
  end

  def count_unique_bfkeys(appeals)
    appeals.map { |appeal| appeal["bfkey"] }.uniq.size
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

    qualifying_appeals || []
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
    if nonsscavlj_number_of_appeals_limit < 0
      fail StandardError, "CaseDistributionLever.nonsscavlj_number_of_appeals_to_move set below 0"
    elsif nonsscavlj_number_of_appeals_limit == 0
      return qualifying_appeals_bfkeys
    end

    if tied_appeals_bfkeys.any?
      if tied_appeals_bfkeys.count < nonsscavlj_number_of_appeals_limit
        qualifying_appeals_bfkeys.push(tied_appeals_bfkeys)
      else
        qualifying_appeals_bfkeys.push(tied_appeals_bfkeys[0..nonsscavlj_number_of_appeals_to_move_index])
      end
    end

    qualifying_appeals_bfkeys.flatten
  end

  def non_ssc_avljs
    VACOLS::Staff.where("sactive = 'A' AND svlj = 'A' AND sattyid <> smemgrp")
  end

  # Method to separate appeals by priority
  def separate_by_priority(appeals)
    return [] if appeals.nil?

    priority_appeals = appeals.select { |appeal| appeal["priority"] == 1 } || []
    non_priority_appeals = appeals.select { |appeal| appeal["priority"] == 0 } || []

    [priority_appeals, non_priority_appeals]
  end

  # Method to calculate remaining eligible appeals
  def calculate_remaining_appeals(all_appeals, moved_priority_appeals, moved_non_priority_appeals)
    return [] if all_appeals.nil?

    remaining_priority_appeals = calculate_remaining_priority_appeals(all_appeals, moved_priority_appeals)
    remaining_non_priority_appeals = calculate_remaining_non_priority_appeals(all_appeals, moved_non_priority_appeals)

    [remaining_priority_appeals, remaining_non_priority_appeals]
  end

  def calculate_remaining_priority_appeals(all_appeals, moved_priority_appeals)
    starting_priority_appeals = all_appeals.select { |appeal| appeal["priority"] == 1 }

    if (moved_priority_appeals - starting_priority_appeals).empty?
      remaining_priority_appeals = (starting_priority_appeals - moved_priority_appeals) || []
    else
      fail StandardError, "An invalid priority appeal was detected in the list of moved appeals: "\
                          "#{moved_priority_appeals - starting_priority_appeals}"
    end

    remaining_priority_appeals
  end

  def calculate_remaining_non_priority_appeals(all_appeals, moved_non_priority_appeals)
    starting_non_priority_appeals = all_appeals.select { |appeal| appeal["priority"] == 0 }

    if (moved_non_priority_appeals - starting_non_priority_appeals).empty?
      remaining_non_priority_appeals = (starting_non_priority_appeals - moved_non_priority_appeals) || []
    else
      fail StandardError, "An invalid non-priority appeal was detected in the list of moved appeals: "\
                          "#{moved_non_priority_appeals - starting_non_priority_appeals}"
    end

    remaining_non_priority_appeals
  end

  # Method to fetch non-SSC AVLJs SATTYIDS that appeals were moved to location '63'
  def fetch_moved_sattyids(moved_appeals)
    return [] if moved_appeals.nil?

    moved_appeals.map { |appeal| VACOLS::Staff.find_by(sattyid: appeal["vlj"]) }
      .compact
      .uniq
      .map(&:sattyid) || []
  end

  def nonsscavlj_number_of_appeals_limit
    @nonsscavlj_number_of_appeals_limit ||= CaseDistributionLever.nonsscavlj_number_of_appeals_to_move || 0
  end

  def nonsscavlj_number_of_appeals_to_move_index
    @nonsscavlj_number_of_appeals_to_move_index ||= nonsscavlj_number_of_appeals_limit - 1
  end

  def create_returned_appeal_job
    ReturnedAppealJob.create!(
      started_at: Time.zone.now,
      stats: { message: "Job started" }.to_json
    )
  end

  def check_appeals_available(moved_appeals, returned_appeal_job)
    if moved_appeals.nil?
      complete_returned_appeal_job(returned_appeal_job, Constants.DISTRIBUTION.no_records_moved_message, [])
      send_job_slack_report(NO_RECORDS_FOUND_MESSAGE)
      throw(:abort)
    end
  end

  def handle_error(error, returned_appeal_job)
    @start_time ||= Time.zone.now
    message = "Job failed with error: #{error.message}"
    errored_returned_appeal_job(returned_appeal_job, message)
    duration = time_ago_in_words(@start_time)
    slack_service.send_notification("<!here>\n [ERROR] after running for #{duration}: #{error.message}",
                                    self.class.name)
    log_error(error)
    message
  end

  def complete_returned_appeal_job(returned_appeal_job, message, appeals)
    appeals ||= []
    returned_appeal_job.update!(
      completed_at: Time.zone.now,
      stats: { message: message }.to_json,
      returned_appeals: appeals.map { |appeal| appeal["bfkey"] }.uniq
    )
  end

  def errored_returned_appeal_job(returned_appeal_job, message)
    returned_appeal_job.update!(
      errored_at: Time.zone.now,
      stats: { message: message }.to_json
    )
  end

  def send_job_slack_report(slack_message)
    if slack_message.blank?
      fail StandardError, "Slack message cannot be empty or nil"
    end

    slack_service.send_notification(slack_message.join("\n"), self.class.name)
  end

  def slack_report
    report = []
    report << "Job performed successfully"
    report << "Total Priority Appeals Moved: #{@filtered_appeals[:priority_appeals_count]}"
    report << "Total Non-Priority Appeals Moved: #{@filtered_appeals[:non_priority_appeals_count]}"
    report << "Total Remaining Priority Appeals: #{@filtered_appeals[:remaining_priority_appeals_count]}"
    report << "Total Remaining Non-Priority Appeals: #{@filtered_appeals[:remaining_non_priority_appeals_count]}"
    report << "SATTYIDs of Non-SSC AVLJs Moved: #{@filtered_appeals[:grouped_by_avlj].join(', ')}"
    report
  end
end
