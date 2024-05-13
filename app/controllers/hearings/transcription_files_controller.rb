# frozen_string_literal: true

class Hearings::TranscriptionFilesController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_page_not_found
  before_action :verify_access_to_hearings, only: [:download_transcription_file]
  before_action :verify_user_organization, only: [:transcription_file_dispatch]

  def verify_user_organization
    if !TranscriptionTeam.singleton.user_has_access?(current_user)
      redirect_to "/unauthorized"
    end
  end

  # Downloads file and sends to user's local computer
  def download_transcription_file
    tmp_location = file.fetch_file_from_s3!
    File.open(tmp_location, "r") { |stream| send_data stream.read, filename: file.file_name }
    file.clean_up_tmp_location
  end

  def transcription_file_dispatch
    render "hearings/index"
  end

  def render_page_not_found
    redirect_to "/404"
  end

  private

  def file
    @file ||= TranscriptionFile.find(params[:file_id])
  end
end
