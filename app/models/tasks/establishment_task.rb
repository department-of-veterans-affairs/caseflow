# frozen_string_literal: true

class EstablishmentTask < Task
  validates :parent, presence: true

  def label
    "Establishment Task"
  end

  # :reek:FeatureEnvy
  # :reek:DuplicateMethodCall { max_calls: 2 }
  def format_instructions(request_issues)
    # format the instructions by loading an array and adding it to the instructions
    added_issue_format = []
    request_issues.each do |issue|
      original_special_issue_status = ""
      # ignore issues that don't have mst or pact status
      next if !issue.mst_status && !issue.pact_status

      # Logic for checking if a prior decision from vbms with mst/pact designation was updated in intake process
      if issue.contested_issue_description
        if issue.vbms_mst_status != issue.mst_status || issue.vbms_pact_status != issue.pact_status
          original_special_issue_status = format_special_issues_text(issue.vbms_mst_status, issue.vbms_pact_status).to_s
        end
      end

      special_issue_status = format_special_issues_text(issue.mst_status, issue.pact_status).to_s
      added_issue_format << [
        format_description_text(issue),
        issue.benefit_type.capitalize,
        original_special_issue_status,
        special_issue_status
      ]

      # create record to log the special issues changes
      create_special_issue_changes_record(issue)
    end
    # add edit_issue_format into the instructions array for the task
    instructions << added_issue_format

    save!
  end

  private

  def format_description_text(issue)
    if issue.contested_issue_description || issue.nonrating_issue_category && issue.nonrating_issue_description
      issue.contested_issue_description || issue.nonrating_issue_category + " - " + issue.nonrating_issue_description
    else
      # we should probably remove this before pushing to prod
      "Description unavailable"
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def format_special_issues_text(mst_status, pact_status)
    # same method as issues_update_task
    # format the special issues comment to display the change in the special issues status(es)
    special_issue_phrase = "Special Issues:"

    return special_issue_phrase + " None" if !mst_status && !pact_status
    return special_issue_phrase + " MST, PACT" if mst_status && pact_status
    return special_issue_phrase + " MST" if mst_status
    return special_issue_phrase + " PACT" if pact_status
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # :reek:FeatureEnvy
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
