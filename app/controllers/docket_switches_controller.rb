# frozen_string_literal: true

class DocketSwitchesController < ApplicationController
  include ValidationConcern

  before_action :verify_task_access, only: [:address_ruling, :create]

  validates :address_ruling, using: DocketSwitchesSchemas.address_ruling
  def address_ruling
    DocketSwitch::AddressRuling.new(
      ruling_task: task,
      new_task_type: params[:new_task_type],
      instructions: params[:instructions],
      assigned_by: current_user,
      assigned_to: User.find(params[:assigned_to_user_id])
    ).process!
    render json: {}
  end

  def create
    docket_switch = DocketSwitch.new(*docket_switch_params)
    docket_switch.update(
      selected_task_ids: params[:selected_task_ids],
      new_admin_actions: params[:new_admin_actions]
    )
    # :nocov:
    if docket_switch.errors.present?
      render json: { errors: [detail: docket_switch.errors.full_messages.join(", ")] }, status: :bad_request
      return
    end
    # :nocov:

    docket_switch.process!

    render json: WorkQueue::DocketSwitchSerializer.new(docket_switch).serializable_hash
  end

  private

  def verify_task_access
    if task.assigned_to != current_user
      fail Caseflow::Error::ActionForbiddenError, message: "Only task assignee can perform this action"
    end
  end

  def task
    @task ||= Task.find(params[:task_id])
  end

  def docket_switch_params
    params.permit(
      :disposition,
      :task_id,
      :receipt_date,
      :context,
      :old_docket_stream_id,
      :docket_type,
      granted_request_issue_ids: []
    )
  end
end
