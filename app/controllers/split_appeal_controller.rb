# frozen_string_literal: true

class SplitAppealController < ApplicationController
  #protect_from_forgery with: :exception

  def split_appeal
    if FeatureToggle.enabled?(:split_appeal_workflow)
      #Missing original appeal Issues and would have to be added to the payload of the useContext in ReviewAppealView
      appeal_id = params[:appeal_id]
      split_issue = params[:appeal_split_issues]
      split_other_reason = params[:split_other_reason]
      split_reason = params[:split_reason]

      render json: { message: "Success" }

      # render json: { message: params.errors[0] }, status: :bad_request

      # get appeal from params
      appeal = Appeal.find(appeal_id)

      # duplicate appeal
      dup_appeal = appeal.amoeba_dup

      # save the duplicate
      dup_appeal.save

      # Setting the user_css_id
      user_css_id = params[:user]

      # run extra duplicate methods to finish split
      dup_appeal.finalize_split_appeal(appeal, user_css_id)

      create_split_record = [
        appeal_id = dup_appeal.id,
        appeal_type = dup_appeal.docket_type,
        appeal_uuid = dup_appeal.uuid,
        created_at = Time.zone.now.utc,
        created_by_id = current_user.id,
        original_appeal_id = appeal.id,
        original_appeal_uuid = appeal.uuid,
        original_request_issue_ids = appeal.request_issues.ids,
        relationship_type = "split_appeal",
        split_other_reason = split_other_reason,
        split_reason = split_reason,
        split_request_issue_ids = split_issue.keys,
        updated_at = Time.zone.now.utc,
        updated_by_id = current_user.id,
        working_split_status = Constants.TASK_STATUSES.in_progress
      ]
      SplitCorrelationTable.create!(appeal_id: create_split_record[0], appeal_type: create_split_record[1], appeal_uuid: create_split_record[2], created_at: create_split_record[3], created_by_id: create_split_record[4], original_appeal_id: create_split_record[5], original_appeal_uuid: create_split_record[6], original_request_issue_ids: create_split_record[7], relationship_type: create_split_record[8], split_other_reason: create_split_record[9], split_reason: create_split_record[10], split_request_issue_ids: create_split_record[11], updated_at: create_split_record[12], updated_by_id: create_split_record[13], working_split_status: create_split_record[14])
      original_request_issue_ids.each do |id|
        original_request_issue_id = id
        original_request_issue = RequestIssue.find_by_id(original_request_issue_id)
        original_request_issue.update!(
          split_issue_status: Constants.TASK_STATUSES.on_hold,
          updated_at: Time.zone.now.utc
        )
      end

      split_request_issue_ids.each do |id|
        split_request_issue_id = id
        split_request_issue = RequestIssue.find_by_id(split_request_issue_id)
        split_request_issue.update!(
          split_issue_status: Constants.TASK_STATUSES.in_progress,
          updated_at: Time.zone.now.utc
        )
      end
    end
  end
end
