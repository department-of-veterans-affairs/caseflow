# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    params

    render json: { message: "Success" }

    # render json: { message: params.errors[0] }, status: :bad_request

    # get appeal from params
    appeal = Appeal.find(params[:appeal_id])

    # duplicate appeal
    dup_appeal = appeal.amoeba_dup

    # save the duplicate
    dup_appeal.save

    # run extra duplicate methods to finish split
    dup_appeal.finalize_split_appeal(appeal, user_css_id)
  end
end
