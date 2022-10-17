class SplitCorrelationTable < ApplicationController
  def create_split_record
    appeal = Appeal.find(appeal_id)
    dup_appeal = appeal.amoeba_dup
    dup_appeal.save
    user_css_id = params[:user]
    dup_appeal.finalize_split_appeal(appeal, user_css_id)

    split_record = SplitCorrelationTable.new
    (
      appeal_id = dup_appeal.id,
      appeal_type = dup_appeal.docket_type,
      appeal_uuid = dup_appeal.uuid,
      created_at = Time.zone.now.utc,
      created_by_id = user_css_id.id,
      original_appeal_id = appeal.id,
      original_appeal_uuid = appeal.uuid,
      original_request_issue_ids = appeal.request_issues.ids,
      relationship_type = "split_appeal",
      split_other_reason = split_other_reason,
      split_reason = split_reason,
      split_request_issue_ids = split_issue,
      updated_at = Time.zone.now.utc,
      updated_by_id = user_css_id,
      working_split_status = Constants.TASK_STATUSES.in_progress
    )
  end
end
