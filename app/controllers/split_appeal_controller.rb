# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    if FeatureToggle.enabled?(:split_appeal_workflow)
      # create transaction for split appeal validation
      Appeal.transaction do
        # Returns a 404 Not Found error if the appeal can not be found to be split
        begin
          Appeal.find(params[:appeal_id])
        rescue StandardError
          return render plain: "404 Not Found", status: :not_found
        end
        # process the split with params from payload
        process_split(params)
      end
    end
  end

  private

  def process_split(params)
    appeal = Appeal.find(params[:appeal_id])
    # set the appeal_split_process to true
    appeal.appeal_split_process = true
    # duplicate appeal
    dup_appeal = appeal.amoeba_dup
    # save the duplicate
    dup_appeal.save!
    create_split_task(appeal, params)
    # run extra duplicate methods to finish split
    dup_appeal.finalize_split_appeal(appeal, params)
    # set the appeal split process to false
    appeal.appeal_split_process = false
    dup_appeal.reload
    appeal.reload
    render json: { split_appeal: dup_appeal, original_appeal: appeal }, status: :created
  end

  def create_split_task(appeal, params)
    split_other_reason = params[:split_other_reason]
    split_reason = params[:split_reason]
    user_css_id = params[:user_css_id]

    split_user = User.find_by_css_id user_css_id
    instructions = if split_other_reason.strip.empty?
                     split_reason
                   else
                     split_other_reason
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
  end
end
