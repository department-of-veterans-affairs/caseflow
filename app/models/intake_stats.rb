class IntakeStats < Caseflow::Stats
  INTERVALS = [:daily, :weekly, :monthly, :fiscal_yearly].freeze

  # Time to wait before recalculating stats
  THROTTLE_RECALCULATION_PERIOD = 20.minutes

  class << self
    def throttled_calculate_all!
      return if last_calculated_at && last_calculated_at > THROTTLE_RECALCULATION_PERIOD.ago

      calculate_all!(clear_cache: true)
      Rails.cache.write(cache_key, Time.zone.now.to_i)
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
      sum = 0.0
      values.each { |v| sum += v }
      sum.to_f / values.count.to_f
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
    end
  }.freeze
end
