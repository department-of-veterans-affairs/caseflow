class UpdateVacatedDecisionIssueIdsDescriptionOnPostDecisionMotion < ActiveRecord::Migration[5.1]
  def change
    change_column_comment :post_decision_motions, :vacated_decision_issue_ids, "When a motion to vacate is partially granted, this includes an array of the appeal's decision issue IDs that were chosen for vacatur in this post-decision motion. For full grant, this includes all prior decision issue IDs." 
  end
end
