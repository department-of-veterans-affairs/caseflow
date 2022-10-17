# frozen_string_literal: true

class SplitCorrelationTable < CaseflowRecord
  class URLPathMissingError < StandardError; end
  # f1b68d5f-1c40-4807-bde5-e6ee4652a732
  # Creates the split appeal record in Caseflow and with table being referenced in tableau.
  # Creation of the table records is subject to change in area of relationship_type & working_split_status

  private 

  #def create_split_record
  #  # Performs a query to see if the orginal apeal UUID has been split and if not found, creates the record.
  #  # It also updates the original request issues to on_hold for the original appeal.
  #  if SplitCorrelationTable.find_by(original_appeal_uuid: appeal.uuid) == false
  #    SplitCorrelationTable.create!(
  #      appeal_id: dup_appeal.id,
  #      appeal_type: dup_appeal.docket_type,
  #      appeal_uuid: dup_appeal.uuid,
  #      created_at: Time.zone.now.utc,
  #      created_by_id: user_css_id,
  #      original_appeal_id: appeal.id,
  #      original_appeal_uuid: appeal.uuid,
  #      original_request_issue_ids: appeal.request_issues.ids,
  #      relationship_type: "split_appeal",
  #      split_other_reason: split_other_reason,
  #      split_reason: split_reason,
  #      split_request_issue_ids: split_issue,
  #      updated_at: Time.zone.now.utc,
  #      updated_by_id: user_css_id,
  #      working_split_status: Constants.TASK_STATUSES.in_progress
  #    )
  #    # iterate over the request issues array and update accordingly for old & new
  #  end
  #end
  
  def create_split_record
    Rails.logger.info(
      "Trying to create split record for Appeal Id #{original_appeal_id} or UUID #{original_appeal_uuid}."
    )
    begin
      split_record = SplitCorrelationTable.new
      update!(
        appeal_id: dup_appeal.id,
        appeal_type: dup_appeal.docket_type,
        appeal_uuid: dup_appeal.uuid,
        created_at: Time.zone.now.utc,
        created_by_id: user_css_id,
        original_appeal_id: appeal.id,
        original_appeal_uuid: appeal.uuid,
        original_request_issue_ids: appeal.request_issues.ids,
        relationship_type: "split_appeal",
        split_other_reason: split_other_reason,
        split_reason: split_reason,
        split_request_issue_ids: split_issue,
        updated_at: Time.zone.now.utc,
        updated_by_id: user_css_id,
        working_split_status: Constants.TASK_STATUSES.in_progress
      )
      split_record.save
    rescue StandardError => error
      Raven.capture_exception(error: error)
      raise error
    end
  end
end
