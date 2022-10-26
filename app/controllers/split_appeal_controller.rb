# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    if FeatureToggle.enabled?(:split_appeal_workflow)
      # create transaction for split appeal validation
      Appeal.transaction do
        appeal_id = params[:appeal_id]
        split_issue = params[:appeal_split_issues]
        split_other_reason = params[:split_other_reason]
        split_reason = params[:split_reason]

        # get appeal from params
        appeal = Appeal.find(appeal_id)

        # set the appeal_split_process to true
        appeal.appeal_split_process = true

        if appeal
          # duplicate appeal
          dup_appeal = appeal.amoeba_dup

          # save the duplicate
          dup_appeal.save!

          # Setting the user_css_id
          user_css_id = params[:user_css_id]
          split_user = User.find_by_css_id user_css_id

          if split_other_reason.strip.empty?
            instructions = split_reason
          else
            instructions = split_other_reason
          end

          Task.transaction do
            spt = SplitAppealTask.create!(
              appeal: appeal,
              parent: appeal.root_task,
              assigned_to: split_user,
              assigned_by: split_user,
              assigned_at: Time.zone.now
            )
            spt.instructions.push(instructions)
            spt.update!(status: Constants.TASK_STATUSES.completed)
          end

          # run extra duplicate methods to finish split
          dup_appeal.finalize_split_appeal(appeal, user_css_id)

          # set the appeal split process to false
          appeal.appeal_split_process = false

          # send success response
          dup_appeal.reload
          appeal.reload
          render json: { split_appeal: dup_appeal, original_appeal: appeal }, status: :created
        else
          fail ActiveRecord::Rollback
        end
      end
      
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
      SplitCorrelationTable.create!(
        appeal_id: create_split_record[0],
        appeal_type: create_split_record[1],
        appeal_uuid: create_split_record[2],
        created_at: create_split_record[3],
        created_by_id: create_split_record[4],
        original_appeal_id: create_split_record[5],
        original_appeal_uuid: create_split_record[6],
        original_request_issue_ids: create_split_record[7],
        relationship_type: create_split_record[8],
        split_other_reason: create_split_record[9],
        split_reason: create_split_record[10],
        split_request_issue_ids: create_split_record[11],
        updated_at: create_split_record[12],
        updated_by_id: create_split_record[13],
        working_split_status: create_split_record[14]
      )
    
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
