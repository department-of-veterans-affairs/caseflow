# frozen_string_literal: true

class Hearings::TranscriptionContractorsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  rescue_from ActionController::ParameterMissing, with: :render_record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  before_action :verify_transcription_user
  before_action :verify_access_to_hearings, except: [:available_contractors, :filterable_contractors]

  def index
    respond_to do |format|
      format.html do
        render "hearings/index"
      end
      format.json do
        @transcription_contractors = TranscriptionContractor.all
        counts = Transcription.counts_for_this_week
        transcription_contractor_json = @transcription_contractors.as_json
          .each { |contractor| contractor["transcription_count_this_week"] = counts[contractor["id"]] || 0 }
        render json: { transcription_contractors: transcription_contractor_json }
      end
    end
  end

  def filterable_contractors
    contractors = TranscriptionContractor.select(:id, :name)
    render json: { transcription_contractors: contractors }
  end

  def available_contractors
    contractors = TranscriptionContractor.where(is_available_for_work: true).select(:id, :name)
    today = Time.zone.today
    standard_date = today + 15.days + Holidays.between(today, today + 15.days, :federal_reserve, :observed).length.days
    expedited_date = today + 5.days + Holidays.between(today, today + 5.days, :federal_reserve, :observed).length.days
    render json: {
      transcription_contractors: contractors,
      return_dates: [standard_date.to_formatted_s(:short_date), expedited_date.to_formatted_s(:short_date)]
    }
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
