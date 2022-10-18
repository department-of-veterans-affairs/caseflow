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

        render json: { message: "Success" }

        # render json: { message: params.errors[0] }, status: :bad_request

        # get appeal from params
        appeal = Appeal.find(appeal_id)

        # set the appeal_split_process to true
        appeal.appeal_split_process = true

        # duplicate appeal
        dup_appeal = appeal.amoeba_dup

        # save the duplicate
        dup_appeal.save!

        # Setting the user_css_id
        user_css_id = params[:user]

        # run extra duplicate methods to finish split
        dup_appeal.finalize_split_appeal(appeal, user_css_id)

        # set the appeal split process to false
        appeal.appeal_split_process = false
      end
    end
  end
end
