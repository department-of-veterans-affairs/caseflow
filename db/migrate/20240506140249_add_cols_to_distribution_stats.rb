class AddColsToDistributionStats < ActiveRecord::Migration[6.0]
  def change
    add_column :distribution_stats, :legacy_priority_stats, :jsonb, comment: "Priority statistics for any VACOLS Docket"
    add_column :distribution_stats, :hearing_priority_stats, :jsonb, comment: "Priority statistics for Hearings Docket"
    add_column :distribution_stats, :direct_review_priority_stats, :jsonb, comment: "Priority statistics for Direct Review Docket"
    add_column :distribution_stats, :evidence_submission_priority_stats, :jsonb, comment: "Priority statistics for Evidence Submission Docket"

    add_column :distribution_stats, :legacy_stats, :jsonb, comment: "Statistics for any VACOLS Docket"
    add_column :distribution_stats, :hearing_stats, :jsonb, comment: "Statistics for Hearings Docket"
    add_column :distribution_stats, :direct_review_stats, :jsonb, comment: "Statistics for Direct Review Docket"
    add_column :distribution_stats, :evidence_submission_stats, :jsonb, comment: "Statistics for Evidence Submission Docket"

    add_column :distribution_stats, :judge_stats, :jsonb, comment: "Statistics that are specific to judge"
    add_column :distribution_stats, :ineligible_judge_stats, :jsonb, comment: "Statistics about appeals tied to ineligible judges"
  end
end

