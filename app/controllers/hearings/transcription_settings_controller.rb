# frozen_string_literal: true

class Hearings::TranscriptionSettingsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  before_action :verify_access_to_hearings

  def index
    respond_to do |format|
      format.html do
        render "hearings/index"
      end

      format.json do
        @transcription_contractors = TranscriptionContractor.all
        render json: { transcription_contractors: @transcription_contractors }
      end
    end
  end

  def show
    respond_to do |format|
      format.html do
        render "hearings/index"
      end

      format.json do
        @transcription_contractor = TranscriptionContractor.find(params[:id])
        render json: { transcription_contractor: @transcription_contractor }
      end
    end
  end

  def render_record_not_found
    render json: {
      "errors": [
        "title": "Record Not Found",
        "detail": "Record with that ID is not found"
      ]
    }, status: :not_found
  end
end
