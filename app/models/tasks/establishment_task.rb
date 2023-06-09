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
      original_special_issue_status = ""
      # ignore issues that don't have mst or pact status
      next if !issue.mst_status && !issue.pact_status

      # Logic for checking if a prior decision from vbms with mst/pact designation was updated in intake process
      if issue.vbms_mst_status || issue.vbms_pact_status
        if issue.vbms_mst_status != issue.mst_status || issue.vbms_pact_status != issue.pact_status
          original_special_issue_status = format_special_issues_text(issue.vbms_mst_status, issue.vbms_pact_status).to_s
        end
      end
      special_issue_status = format_special_issues_text(issue.mst_status, issue.pact_status).to_s
      added_issue_format << [format_description_text(issue), original_special_issue_status, special_issue_status]

      # create record to log the special issues changes
      create_special_issue_changes_record(issue)
    end
    # add edit_issue_format into the instructions array for the task
    instructions << added_issue_format

    save!
  end

  private

  def format_description_text(issue)
    issue.contested_issue_description || issue.nonrating_issue_category + " - " + issue.nonrating_issue_description
  end

  def format_special_issues_text(mst_status, pact_status)
    # format the special issues comment to display the change in the special issues status(es)
    s = "Special issues:"

    return s + " None" if !mst_status && !pact_status
    return s + " MST, PACT" if mst_status && pact_status
    return s + " MST" if mst_status
    return s + " PACT" if pact_status
  end

  def create_special_issue_changes_record(issue)
    # create SpecialIssueChange record to log the changes
    SpecialIssueChange.create!(
      issue_id: issue.id,
      appeal_id: appeal.id,
      appeal_type: "Appeal",
      task_id: id,
      created_at: Time.zone.now.utc,
      created_by_id: RequestStore[:current_user].id,
      created_by_css_id: RequestStore[:current_user].css_id,
      original_mst_status: issue.mst_status,
      original_pact_status: issue.pact_status,
      mst_from_vbms: issue&.vbms_mst_status,
      pact_from_vbms: issue&.vbms_pact_status,
      change_category: "Established Issue"
    )
  end
end
