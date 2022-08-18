# frozen_string_literal: true

class SplitAppealController < ApplicationController
  skip_before_action :verify_authenticity_token # REMOVE THIS BEFORE PUUUUSH
  
  def split_appeal
    # split appeal logic here
    # binding.pry
    params.require(:appeal_id)
    # chris logic 
    # render json: Appeal.find(params[:appeal_id])
    # binding.pry

    return render json: { message: "Success!" } 

    # render json: { message: params.errors[0] }, status: :bad_request
  end
end
