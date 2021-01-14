# frozen_string_literal: true

# Controller to edit NOD dates and store the related info in the nod_date_updates table

class NodDateUpdatesController < ApplicationController
  #before_action :validate_access
  
  def create
    binding.pry
    nod_date_update = NodDateUpdate.create!(create_params) 
    render json: { nod_date_update: nod_date_update }, status: :created
  end
  
  #validates :update_nod_date, using: AppealsSchemas.update_nod_date
  def update
    binding.pry
    if params[:receipt_date]
      appeal.update_receipt_date!(receipt_date: params[:receipt_date])
    end
    create
  end
  
  private
  
  def appeal
    @appeal ||= Appeal.find_by_uuid(params[:appeal_id])
  end
  
  def create_params
    params.merge!(user_id: current_user.id, appeal_id: appeal.id)
    params.require(required_params)
  end
  
  def required_params
      [
        :appeal_id,
        :old_date,
        :new_date,
        :user_id,
        :change_reason,
        :created_at,
        :updated_at
      ]
  end
end
  