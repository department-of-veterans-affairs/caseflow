# frozen_string_literal: true

class IssuesUpdateTask < Task
  validates :parent, presence: true

  def label
    "Issues Update Task"
  end

  def format_instructions(change_type, issue_category, benefit_type, original_mst, original_pact, edit_mst = nil, edit_pact = nil,
                          _mst_edit_reason = nil, _pact_edit_reason = nil)
    # format the instructions by loading an array and adding it to the instructions
    edit_issue_format = []
    # add the change type
    edit_issue_format << change_type
    edit_issue_format << benefit_type
    edit_issue_format << issue_category
    original_comment = format_special_issues_text(original_mst, original_pact).to_s
    edit_issue_format << original_comment

    # format edit if edit values are given
    unless edit_mst.nil? || edit_pact.nil?
      updated_comment = format_special_issues_text(edit_mst, edit_pact).to_s
      edit_issue_format << updated_comment
    end

    # add the MST and PACT edit reasons. Removed on release but kept incase we need it for the future
    # edit_issue_format << mst_edit_reason
    # edit_issue_format << pact_edit_reason

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
