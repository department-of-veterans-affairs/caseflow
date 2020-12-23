# frozen_string_literal: true

class DocketSwitchesController < ApplicationController  
  def create
    docket_switch = DocketSwitch.new(*docket_switch_params)
    if docket_switch.errors.present?
      render json: { errors: [detail: docket_switch.errors.full_messages.join(", ")] }, status: :bad_request
      return
    end
    docket_switch.save
    render json: {}
  end

  private

  def docket_switch_params
    params.permit(:disposition, :task_id, :receipt_date, :context, :old_docket_stream_id)
  end
end
