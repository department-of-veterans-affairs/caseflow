# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    params.require(:appeal_id)

    return render json: { message: "Success!" }

    # render json: { message: params.errors[0] }, status: :bad_request
  end
end
