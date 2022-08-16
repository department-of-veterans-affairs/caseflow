# frozen_string_literal: true

class SplitAppealController < ApplicationController
  def split_appeal
    # split appeal logic here
    result = true

    # chris logic 
    render json: Appeal.find(params[:appeal_id])

    return render json: { message: "Success!" } if result.success?

    render json: { message: result.errors[0] }, status: :bad_request
  end
end
