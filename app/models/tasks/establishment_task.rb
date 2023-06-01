# frozen_string_literal: true

class EstablishmentTask < Task
  validates :parent, presence: true

  def label
    "Establishment Task"
  end

  def format_instructions(request_issues)
    # format the instructions by loading an array and adding it to the instructions
    added_issue_format = []
    request_issues.each do |issue|
      special_issue_status = "#{format_special_issues_text(issue.mst_status, issue.pact_status)}"
      added_issue_format << [format_description_text(issue), special_issue_status]
    end
    # add edit_issue_format into the instructions array for the task
    instructions << added_issue_format

    save!
  end

  private

  def format_description_text(issue)
    issue.nonrating_issue_category + " - " + issue.nonrating_issue_description || issue.contested_issue_description
  end

  def format_special_issues_text(mst_status, pact_status)
    # format the special issues comment to display the change in the special issues status(es)
    s = "Special issues:"

    return s + " None" if !mst_status && !pact_status
    return s + " MST, PACT" if mst_status && pact_status
    return s + " MST" if mst_status
    return s + " PACT" if pact_status
  end
end
