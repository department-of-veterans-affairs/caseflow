# frozen_string_literal: true

class PostDecisionMotionsController < ApplicationController
  def create
    result = PostDecisionMotion.new(motion_params)

    if result.valid?
      result.save
      flash[:success] = "Disposition saved!"
    else
      render json: { errors: [detail: result.errors.full_messages.join(", ")] }, status: :bad_request
    end
  end

  private

  def motion_params
    params.require(:post_decision_motion).permit(:disposition, :task_id)
  end
end
