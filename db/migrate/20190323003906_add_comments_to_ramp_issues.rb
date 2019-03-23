class AddCommentsToRampIssues < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:ramp_issues, "Keeps track of issues added to an End Product as contentions for RAMP Reviews.")

    change_column_comment(:ramp_issues, :contention_reference_id, "The contention_id for the contention created in VBMS that corresponds to this RAMP issue.")

    change_column_comment(:ramp_issues, :description, "The description of the issues, which come from contentions on the End Product Establishment.")

    change_column_comment(:ramp_issues, :review_id, "The ID of the RAMP Election or RAMP Refiling this issue is connected to.")

    change_column_comment(:ramp_issues, :review_type, "Whether this issue is connected to a RAMP Election or RAMP Refiling.")

    change_column_comment(:ramp_issues, :source_issue_id, "For a RAMP Refiling, the ID of the source issue from the completed RAMP Election.")
  end
end
