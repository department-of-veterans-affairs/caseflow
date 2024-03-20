# frozen_string_literal: true

class Hearings::TranscriptionFilesController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActionController::UnknownFormat, with: :render_page_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_page_not_found
  before_action :verify_access_to_hearings, only: [:download_transcription_file]

  def index
    nil
  end

  def update
    nil
  end

  def create
    nil
  end

  # Downloads file and sends to user's local computer
  def download_transcription_file
    hearing_id = params[:hearing_id]
    respond_to do |format|
      format.any(:vtt, :mp3, :mp4, :csv) do |_|
        type = format.format&.symbol.to_s
        file = TranscriptionFile.find_by!(hearing_id: hearing_id, file_type: type)
        tmp_location = file.download_from_s3
        File.open(tmp_location, "r") { |f| send_data f.read }
        File.delete(tmp_location) if File.exist?(tmp_location)
      end
    end
  end

  def render_page_not_found
    redirect_to "/404"
  end
end
