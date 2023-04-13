# frozen_string_literal: true

class IssuesUpdateTask < Task
  validates :parent, presence: true

  def label
    "Issues Update Task"
  end

  def format_instructions(issue_category, original_mst, original_pact, edit_mst, edit_pact)
    comment_header = "Edited Issue:"

    # format original
    original_comment = "\nORIGINAL:\n#{issue_category}#{format_special_issues_text(original_mst, original_pact)}"

    # format edit
    updated_comment = "\nUPDATED:\n#{issue_category}#{format_special_issues_text(edit_mst, edit_pact)}"

    # concat the strings into the instructions
    instructions << comment_header + original_comment + updated_comment
    save!
  end

  private

  def format_special_issues_text(mst_status, pact_status)
    # format the special issues comment to display the change in the special issues status(es)
    s = "\nSpecial Issues:"

    return s + " None" if !mst_status && !pact_status

    s + " MST" if mst_status
    s + " PACT" if pact_status
  end
end
