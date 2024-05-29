# frozen_string_literal: true

class IssuesUpdateTask < Task
  validates :parent, presence: true

  def label
    "Issues Update Task"
  end

  # :reek:FeatureEnvy
  def format_instructions(set)
    # format the instructions by loading an array and adding it to the instructions
    edit_issue_format = []
    # add the change type
    edit_issue_format << set.change_type
    edit_issue_format << set.benefit_type
    edit_issue_format << set.issue_category
    original_comment = format_special_issues_text(set.original_mst, set.original_pact).to_s
    edit_issue_format << original_comment

    # format edit if edit values are given
    unless set.edit_mst.nil? || set.edit_pact.nil?
      updated_comment = format_special_issues_text(set.edit_mst, set.edit_pact).to_s
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

  # rubocop:disable Metrics/CyclomaticComplexity
  def format_special_issues_text(mst_status, pact_status)
    # format the special issues comment to display the change in the special issues status(es)
    special_issue_status = "Special Issues:"

    return special_issue_status + " None" if !mst_status && !pact_status
    return special_issue_status + " MST, PACT" if mst_status && pact_status
    return special_issue_status + " MST" if mst_status
    return special_issue_status + " PACT" if pact_status
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
