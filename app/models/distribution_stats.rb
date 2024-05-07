# frozen_string_literal: true

class DistributionStats < CaseflowRecord
  belongs_to :distribution

  def initialize
    puts "test"
    super
  end

  def self.from_hash(stats)

    create_distribution_stats!(
      statistics: stats,
      levers: CaseDistributionLever.snapshot
    )
  end
end
