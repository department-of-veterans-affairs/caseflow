# frozen_string_literal: true

# Controller to edit NOD dates and store the related info in the nod_date_updates table

class NodDateUpdatesController < ApplicationController
  include ValidationConcern

  before_action :react_routed

  validates :update, using: NodDateUpdatesSchemas.update
  def update
    new_date = params[:receipt_date]
    timeliness_error = appeal.validate_all_issues_timely!(new_date)
    if !timeliness_error
      nod_date_update = NodDateUpdate.create!(updated_params)
      appeal.update_receipt_date!(receipt_date: params[:receipt_date])
      render json: {
        nodDate: appeal.receipt_date,
        docketNumber: appeal.docket_number,
        changeReason: nod_date_update.change_reason,
        nodDateUpdate: WorkQueue::NodDateUpdateSerializer.new(nod_date_update).serializable_hash[:data][:attributes]
      }, status: :created
    else
      render json: { "errors": timeliness_error }
    end
  end

  private

  def appeal
    @appeal ||= Appeal.find_by_uuid(params[:appeal_id])
  end

  def updated_params
    params.merge!(
      user_id: current_user.id,
      appeal_id: appeal.id,
      old_date: appeal.receipt_date,
      new_date: params["receipt_date"],
      change_reason: params["change_reason"]
    )
    params.permit(required_params)
  end

  def required_params
    [
      :user_id,
      :appeal_id,
      :old_date,
      :new_date,
      :change_reason,
      :created_at,
      :updated_at
    ]
  end
end
