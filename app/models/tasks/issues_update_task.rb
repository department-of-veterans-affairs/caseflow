# frozen_string_literal: true

class IssuesUpdateTask < Task
  validates :parent, presence: true

  def label
    "Issues Update Task"
  end

  # accepts the task type (edit, remove, add), issue category, original pact/mst, and updated pact/mst (if applicable)
  # formats the instructions to display on the case timeline
  def format_instructions(change_type, issue_category, original_mst, original_pact, edit_mst = "", edit_pact = "",
  mst_edit_reason = "", pact_edit_reason = "")
    # format the instructions by loading an array and adding it to the instructions
    edit_issue_format = []
    edit_issue_format << change_type
    edit_issue_format << issue_category
    original_comment = "#{format_special_issues_text(original_mst, original_pact)}"
    edit_issue_format << original_comment

    # format edit
    edit_issue_format << issue_category
    updated_comment = "#{format_special_issues_text(edit_mst, edit_pact)}"
    edit_issue_format << updated_comment

    #add the MST and PACT edit reasons
    edit_issue_format << mst_edit_reason
    edit_issue_format << pact_edit_reason

    # add edit_issue_format into the instructions array for the task
    instructions << edit_issue_format

    save!
  end

  private

  def format_special_issues_text(mst_status, pact_status)
    # format the special issues comment to display the change in the special issues status(es)
    s = "Special Issues:"

    return s + " None" if !mst_status && !pact_status
    return s + " MST, PACT" if mst_status && pact_status
    return s + " MST" if mst_status
    return s + " PACT" if pact_status
  end
end
