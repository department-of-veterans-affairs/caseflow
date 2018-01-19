class IntakeStats < Caseflow::Stats
  INTERVALS = [:daily, :weekly, :monthly].freeze

  # Used to prevent dates on the line from registering for two time periods
  def self.offset_range(range)
    ((range.first + 1.second)...(range.last + 1.second))
  end

  CALCULATIONS = {
    # Number of opt-in notices mailed by month and to date
    elections_sent: lambda do |range|
      RampElection.where(notice_date: offset_range(range)).count
    end,

    # Number of opt-in elections received by month and FYTD
    elections_successfully_received: lambda do |range|
      RampElection.completed.where(receipt_date: offset_range(range)).count
    end,

    # Average days to respond to RAMP election notice
    average_election_response_time: lambda do |range|
      IntakeStats.percentile(
        :response_time,
        RampElection.completed.where(receipt_date: offset_range(range)),
        50
      )
    end
  }.freeze
end
