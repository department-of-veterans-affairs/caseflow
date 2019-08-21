# frozen_string_literal: true

class PostDecisionMotionsController < ApplicationController
  before_action :verify_task_access

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

  def verify_task_access
    # TODO: check that the task is of motion to vacate VLJ task type
    if task.assigned_to != current_user
      fail Caseflow::Error::ActionForbiddenError, message: "Only task assignee can update disposition"
    end
  end

  def task
    @task ||= Task.find(motion_params[:task_id])
  end

  def motion_params
    # TODO: add assigned to param if motion is granted
    params.require(:post_decision_motion).permit(:disposition, :task_id, :vacate_type)
  end
end
