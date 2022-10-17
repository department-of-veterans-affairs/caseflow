# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

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

      SplitCorrelationTable.create_split_record(
        appeal_id,
        split_issue,
        split_other_reason,
        split_reason,
        appeal,
        dup_appeal,
        user_css_id
      )
    end
  end
end
