# frozen_string_literal: true

class IssuesUpdateTask < Task
  validates :parent, presence: true

  def label
    "Issues Update Task"
  end

  def format_instructions(issue_category, original_mst, original_pact, edit_mst, edit_pact, edit_reason)
    # format the instructions by loading an array and adding it to the instructions
    edit_issue_format = []
    edit_issue_format << issue_category
    original_comment = "#{format_special_issues_text(original_mst, original_pact)}"
    edit_issue_format << original_comment

    # format edit
    edit_issue_format << issue_category
    updated_comment = "#{format_special_issues_text(edit_mst, edit_pact)}"
    edit_issue_format << updated_comment

    # add edit reason on the end
    edit_issue_format << edit_reason

    # add edit_issue_format into the instructions array for the task
    instructions << edit_issue_format
    save!
  end

  private

  def format_special_issues_text(mst_status, pact_status)
    # format the special issues comment to display the change in the special issues status(es)
    s = "Special Issues:"

    return s + " None" if !mst_status && !pact_status

    return s + " MST" if mst_status
    return s + " PACT" if pact_status
    return s + " MST, PACT" if mst_status && pact_status
  end
end
