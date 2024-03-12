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

  # Downloads file and sends to user's local computer
  def download_transcription_file
    hearing_id = params[:hearing_id]
    respond_to do |format|
      format.any(:vtt, :mp3, :mp4, :csv) do |_|
        type = format.format&.symbol
        file = TranscriptionFile.find_by(hearing_id: hearing_id, file_type: type.to_s)
        tmp_location = file.download_from_s3
        File.open(tmp_location, "r") { |f| send_data f.read }
        File.delete(tmp_location) if File.exist?(tmp_location)
      end
    end
  end
end
