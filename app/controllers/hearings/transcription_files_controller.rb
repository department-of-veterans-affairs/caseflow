# frozen_string_literal: true

class TranscriptionFilesController < ApplicationController
  def index
    nil
  end

  def update
    nil
  end

  def create
    nil
  end

  def download_transcription_file
    respond_to do |format|
      format.any(:vtt, :mp3, :mp4, :csv) do |_|
        render json: {
          message: "Route working, showing hearing of id: #{params[:hearing_id]}",
          status: 200
        }
      end
    end
  end
end
