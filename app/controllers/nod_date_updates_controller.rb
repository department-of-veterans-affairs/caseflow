# frozen_string_literal: true

# Controller to edit NOD dates and store the related info in the nod_date_updates table

class NodDateUpdatesController < ApplicationController
  include ValidationConcern

  before_action :verify_access, :react_routed, :set_application
  
  validates :update, using: NodDateUpdatesSchemas.update
  def update
    nod_date_update = NodDateUpdate.create!(updated_params)
    appeal.update_receipt_date!(receipt_date: params[:receipt_date])
    render json: { nod_date_update: nod_date_update }, status: :created
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
      change_reason: params["change_reason"]["value"]
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
