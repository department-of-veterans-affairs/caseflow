class AddCommentsToRampIssues < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:ramp_issues, "Issues added to an end product as contentions for RAMP reviews. For RAMP elections, these are created in VBMS after the end product is established and updated in Caseflow when the end product is synced. For RAMP refilings, these are selected from the RAMP election's issues and added to the RAMP refiling end product that is established.")

    change_column_comment(:ramp_issues, :contention_reference_id, "The ID of the contention created in VBMS that corresponds to the RAMP issue.")

    change_column_comment(:ramp_issues, :description, "The description of the contention in VBMS.")

    change_column_comment(:ramp_issues, :review_id, "The ID of the RAMP election or RAMP refiling for this issue.")

    change_column_comment(:ramp_issues, :review_type, "The type of RAMP review the issue is on, indicating whether this is a RAMP election issue or a RAMP refiling issue.")

    change_column_comment(:ramp_issues, :source_issue_id, "If a RAMP election issue added to a RAMP refiling, it is the source issue for the corresponding RAMP refiling issue.")
  end
end
