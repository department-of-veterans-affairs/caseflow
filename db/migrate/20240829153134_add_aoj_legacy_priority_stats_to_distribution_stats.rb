class AddAojLegacyPriorityStatsToDistributionStats < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      add_column :distribution_stats, :aoj_legacy_priority_stats, :json, comment: "Priority statistics for AOJ Legacy Docket"
      add_column :distribution_stats, :aoj_legacy_stats, :json, comment: "Statistics for AOJ Legacy Docket"
    end
  end
end
