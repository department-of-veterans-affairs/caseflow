# frozen_string_literal: true

class Hearings::TranscriptionSettingsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_page_not_found
  before_action :verify_access_to_hearings

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

  def render_page_not_found
    redirect_to "/404"
  end
end
