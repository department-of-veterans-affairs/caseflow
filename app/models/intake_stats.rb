class IntakeStats < Caseflow::Stats
  INTERVALS = [:daily, :weekly, :monthly, :fiscal_yearly].freeze

  # Time to wait before recalculating stats
  THROTTLE_RECALCULATION_PERIOD = 20.minutes

  # List of all error codes we collect metrics on
  REPORTED_ERROR_CODES = [nil, "no_eligible_appeals", "no_active_appeals", "ramp_election_already_complete"].freeze

  class << self
    def throttled_calculate_all!
      return if last_calculated_at && last_calculated_at > THROTTLE_RECALCULATION_PERIOD.ago

      calculate_all!(clear_cache: true)
      Rails.cache.write(cache_key, Time.zone.now.to_i)
    end

    def intake_series_statuses(range)
      @intake_series_statuses ||= {}
      @intake_series_statuses[range] ||= intake_series(range).map { |intakes| intake_series_status(intakes) }
    end

    private

    # Used to prevent dates on the line from registering for two time periods
    def offset_range(range)
      ((range.first + 1.second)...(range.last + 1.second))
    end

    def last_calculated_at
      return @last_calculated_timestamp if @last_calculated_timestamp

      timestamp = Rails.cache.read(cache_key)
      timestamp && Time.zone.at(timestamp.to_i)
    end

    def cache_key
      "#{name}-last-calculated-timestamp"
    end

    def average(values)
      values.inject(0.0) { |sum, i| sum + i } / values.count
    end

    # Get all RampElectionIntakes for a veteran in the specified range.
    # This is so we can summarize whether the Ramp Election was ultimately successful or what
    # The final error was, even if there were other errors at first.
    def intake_series(range)
      RampElectionIntake
        .where(error_code: REPORTED_ERROR_CODES, completed_at: range)
        .order(:completed_at)
        .group_by(&:veteran_file_number)
        .values
    end

    def intake_series_status(intakes)
      intakes.any?(&:success?) ? "success" : intakes.last.error_code
    end
  end

  CALCULATIONS = {
    # Number of opt-in notices mailed by month and to date
    elections_sent: lambda do |range|
      RampElection.where(notice_date: offset_range(range)).count
    end,

    elections_returned_by_notice_date: lambda do |range|
      RampElection.completed.where(notice_date: offset_range(range)).count
    end,

    # Number of opt-in elections received by month and FYTD
    elections_successfully_received: lambda do |range|
      RampElection.completed.where(receipt_date: offset_range(range)).count
    end,

    # Average days to respond to RAMP election notice
    average_election_response_time: lambda do |range|
      elections = RampElection.completed.where(receipt_date: offset_range(range))
      response_times = elections.map { |e| e.receipt_date.to_time.to_f - e.notice_date.to_time.to_f }
      average(response_times)
    end,

    total_completed: lambda do |range|
      intake_series_statuses(range).count
    end,

    total_sucessfully_completed: lambda do |range|
      intake_series_statuses(range).select { |status| status == "success" }.count
    end,

    total_ineligible: lambda do |range|
      intake_series_statuses(range).reject { |status| status == "success" }.count
    end,

    total_no_eligible_appeals: lambda do |range|
      intake_series_statuses(range).select { |status| status == "no_eligible_appeals" }.count
    end,

    total_no_active_appeals: lambda do |range|
      intake_series_statuses(range).select { |status| status == "no_active_appeals" }.count
    end,

    total_ramp_election_already_complete: lambda do |range|
      intake_series_statuses(range).select { |status| status == "ramp_election_already_complete" }.count
    end
  }.freeze
end
