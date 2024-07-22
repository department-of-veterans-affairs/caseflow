# frozen_string_literal: true

class Hearings::TranscriptionContractorsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  rescue_from ActionController::ParameterMissing, with: :render_record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  before_action :verify_access_to_hearings

  def index
    respond_to do |format|
      format.html do
        render "hearings/index"
      end

      format.json do
        @transcription_contractors = TranscriptionContractor.all
        counts = Transcription
          .where(sent_to_transcriber_date: Time.zone.today.beginning_of_week.yesterday..Time.zone.today)
          .group(:transcription_contractor_id)
          .count
        transcription_contractor_json = @transcription_contractors.as_json
          .each { |contractor| contractor["transcription_count"] = counts[contractor["id"]] || 0 }
        render json: { transcription_contractors: transcription_contractor_json }
      end
    end
  end

  def show
    render json: { transcription_contractor: transcription_contractor }
  end

  def create
    transcription_contractor = TranscriptionContractor.create!(transcription_contractor_params)
    render json: { transcription_contractor: transcription_contractor }, status: :created
  end

  def update
    transcription_contractor.update!(transcription_contractor_params)
    render json: { transcription_contractor: transcription_contractor }, status: :accepted
  end

  def destroy
    transcription_contractor.destroy!
    render json: {}
  end

  private

  def transcription_contractor
    @transcription_contractor ||= TranscriptionContractor.find(params[:id])
  end

  def render_record_not_found
    render json: {
      "errors": [
        "title": "Contractor Not Found",
        "detail": "Contractor with that ID is not found"
      ]
    }, status: :not_found
  end

  def render_record_invalid(error)
    render json: {
      "errors": [
        "title": error.class.to_s,
        "detail": error.message
      ]
    }, status: :bad_request
  end

  def transcription_contractor_params
    params
      .require(:transcription_contractor)
      .permit(:current_goal,
              :directory,
              :email,
              :inactive,
              :is_available_for_work,
              :name,
              :phone,
              :poc)
  end
end
