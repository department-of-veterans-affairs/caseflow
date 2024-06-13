# frozen_string_literal: true

class Hearings::TranscriptionFilesController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_hearings, only: [:download_transcription_file]
  before_action :setup_pagination, only: [:transcription_file_tasks]

  def transcription_file_tasks
    total_count = TranscriptionFile.where(@where).where(@filters).count
    total_pages = (total_count / @page_size).ceil
    transcription_files = TranscriptionFile
      .where(@where)
      .where(@filters)
      .preload(hearing: [appeal: [:advance_on_docket_motion]])
      .limit(@page_size)
      .offset(@page_start)

    render json: {
      docket_line_index: "",
      task_page_count: total_pages,
      tasks: { data: TranscriptionFile.build_transcription_files(transcription_files) },
      tasks_per_page: @page_size,
      total_task_count: total_count
    }
  end

  def download_transcription_file
    tmp_location = file.fetch_file_from_s3!
    File.open(tmp_location, "r") { |stream| send_data stream.read, filename: file.file_name }
    file.clean_up_tmp_location
  end

  private

  def setup_pagination
    @current_page = params[:page].to_i || 1
    @page_size = 15
    @page_start = (@current_page - 1) * @page_size
    @tab = params[:tab] || ""
    @sort_by = params[:sort_by] || "id"
    @where = { file_status: TranscriptionFile.file_status(@tab) }
    @filters = TranscriptionFile.build_filters(params[:filter])
  end

  def file
    @file ||= TranscriptionFile.find(params[:file_id])
  end
end
