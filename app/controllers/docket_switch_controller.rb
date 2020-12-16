class DocketSwitchController < ApplicationController
before_action :verify_task_access, only: [:create]

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def create
    docket_switch = DocketSwitch.new(*docket_switch_params)

    if docket_switch.errors.present?
      render json: { errors: [detail: docket_switch.errors.full_messages.join(", ")] }, status: :bad_request
      return
    end
    render json: {}
  end

  private

  def verify_task_access
    if task.assigned_to != current_user
      fail Caseflow::Error::ActionForbiddenError, message: "Only task assignee can perform this action"
    end
  end

  def task
    @task ||= Task.find(docket_switch_params[:task_id])
  end

  def docket_switch_params
    params.permit(:disposition, :task_id, :receipt_date, :context, :old_docket_stream_id)
  end
end

