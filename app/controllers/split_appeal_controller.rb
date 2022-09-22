# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal    
    appeal_id = params[:appeal_id]
    split_issue = params[:appeal_split_issues]
    split_other_reason = params[:split_other_reason]
    split_reason = params[:split_reason]
    
    render json: { message: "Success" }
    # render json: { message: params.errors[0] }, status: :bad_request
  end
end
