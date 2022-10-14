# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    if FeatureToggle.enabled?(:split_appeal_workflow)

      appeal_id = params[:appeal_id]
      split_issue = params[:appeal_split_issues]
      split_other_reason = params[:split_other_reason]
      split_reason = params[:split_reason]

      render json: { message: "Success" }
      # get appeal from params
      appeal = Appeal.find(appeal_id)
      if (appeal)
        # duplicate appeal & save 
        dup_appeal = appeal.amoeba_dup
        dup_appeal.save
  
        # Setting the user_css_id
        user_css_id = RequestStore[:current_user]
  
        if split_other_reason.strip.empty?
          instructions = split_reason
        else
          instructions= split_other_reason
        end
        
        Task.transaction do
          spt = SplitAppealTask.create!(appeal: appeal,
              parent: appeal.root_task,
              assigned_to: user_css_id,
              assigned_by: user_css_id,
              assigned_at: Time.zone.now)
          
          spt.instructions.push(instructions)
          spt.update!(status: Constants.TASK_STATUSES.completed)
          dup_appeal.finalize_split_appeal(appeal, user_css_id.css_id)
        end
      else
        raise ActiveRecord::Rollback
      end
    end
  end
