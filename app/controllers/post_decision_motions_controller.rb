# frozen_string_literal: true

class PostDecisionMotionsController < ApplicationController
  before_action :verify_task_access

  def create
    motion_updater = PostDecisionMotionUpdater.new(task, motion_params)
    motion_updater.process

    if motion_updater.errors.present?
      render json: { errors: [detail: motion_updater.errors.full_messages.join(", ")] }, status: :bad_request
      return
    end
    flash[:success] = "Disposition saved!"
    render json: {}
  end

  private

  def verify_task_access
    if task.assigned_to != current_user
      fail Caseflow::Error::ActionForbiddenError, message: "Only task assignee can update disposition"
    end
  end

  def task
    @task ||= JudgeAddressMotionToVacateTask.find(motion_params[:task_id])
  end

  def motion_params
    params.permit(:disposition, :task_id, :vacate_type, :instructions, :assigned_to_id, vacated_decision_issue_ids: [])
  end
end
