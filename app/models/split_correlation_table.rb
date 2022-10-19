# frozen_string_literal: true

class SplitCorrelationTable < CaseflowRecord
  #def create_split_record
  #  appeal = Appeal.find(appeal_id)
  #  dup_appeal.save
  #  user_css_id = params[:user]
  #  dup_appeal.finalize_split_appeal(appeal, user_css_id)
#
  #  SplitCorrelationTable.create!(
  #    appeal_id: create_split_record[0],
  #    appeal_type: create_split_record[1],
  #    appeal_uuid: create_split_record[2],
  #    created_at: create_split_record[3],
  #    created_by_id: create_split_record[4],
  #    original_appeal_id: create_split_record[5],
  #    original_appeal_uuid: create_split_record[6],
  #    original_request_issue_ids: create_split_record[7],
  #    relationship_type: create_split_record[8],
  #    split_other_reason: create_split_record[9],
  #    split_reason: create_split_record[10],
  #    split_request_issue_ids: create_split_record[11],
  #    updated_at: create_split_record[12],
  #    updated_by_id: create_split_record[13],
  #    working_split_status: create_split_record[14]
  #  )
#
  #  original_request_issue_ids.each do |id|
  #    original_request_issue_id = id
  #    original_request_issue = RequestIssue.find_by_id(original_request_issue_id)
  #    original_request_issue.update!(
  #      split_issue_status: Constants.TASK_STATUSES.on_hold,
  #      updated_at: Time.zone.now.utc
  #    )
  #  end
#
  #  split_request_issue_ids.each do |id|
  #    split_request_issue_id = id
  #    split_request_issue = RequestIssue.find_by_id(split_request_issue_id)
  #    split_request_issue.update!(
  #      split_issue_status: Constants.TASK_STATUSES.in_progress,
  #      updated_at: Time.zone.now.utc
  #    )
  #  end
  #end
end
