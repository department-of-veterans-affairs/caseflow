class AddColsToDistributionStats < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      add_column :distribution_stats, :legacy_priority_stats, :json, comment: "Priority statistics for any VACOLS Docket"
      add_column :distribution_stats, :hearing_priority_stats, :json, comment: "Priority statistics for Hearings Docket"
      add_column :distribution_stats, :direct_review_priority_stats, :json, comment: "Priority statistics for Direct Review Docket"
      add_column :distribution_stats, :evidence_submission_priority_stats, :json, comment: "Priority statistics for Evidence Submission Docket"

      add_column :distribution_stats, :legacy_stats, :json, comment: "Statistics for any VACOLS Docket"
      add_column :distribution_stats, :hearing_stats, :json, comment: "Statistics for Hearings Docket"
      add_column :distribution_stats, :direct_review_stats, :json, comment: "Statistics for Direct Review Docket"
      add_column :distribution_stats, :evidence_submission_stats, :json, comment: "Statistics for Evidence Submission Docket"

      add_column :distribution_stats, :judge_stats, :json, comment: "Statistics that are specific to judge"
      add_column :distribution_stats, :ineligible_judge_stats, :json, comment: "Statistics about appeals tied to ineligible judges"
    end
  end
end

