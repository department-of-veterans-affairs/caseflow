# frozen_string_literal: true

class Hearings::TranscriptionFilesController < ApplicationController
  # include HearingsConcerns::VerifyAccess

  # before_action :verify_access_to_hearings, only: [:download_transcription_file]
  before_action :setup_pagination, only: [:transcription_file_tasks]

  # TODO: Fix permissions for controllers
  # TODO: Fix page load event in front end component
  # TODO: Fix types column, they're missing for some reason, and need more work

  def transcription_file_tasks
    total_count = TranscriptionFile.where(file_status: @file_status).count
    total_pages = (total_count / @page_size).ceil
    transcription_files = TranscriptionFile
      .where(file_status: @file_status)
      .includes(hearing: [appeal: [:advance_on_docket_motion]])
      .limit(@page_size).offset(@page_start)
    render json: {
      docket_line_index: "",
      task_page_count: total_pages,
      tasks: { data: build_transcription_files(transcription_files) },
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
    @file_status = file_status(@tab)
  end

  def file
    @file ||= TranscriptionFile.find(params[:file_id])
  end

  def hearing_date(transcription_file)
    transcription_file.hearing.hearing_day.scheduled_for.to_formatted_s(:short_date)
  end

  def hearing_type(transcription_file)
    if transcription_file.hearing_type == "LegacyHearing"
      "Legacy"
    else
      "AMA"
    end
  end

  def transcription_file_types(transcription_file)
    types = []
    aod = transcription_file.try(:hearing).try(:appeal).try(:advance_on_docket_motion).try(:granted)
    if aod
      types << "AOD"
    end
    stream_type = transcription_file.try(:hearing).try(:appeal).try(:stream_type)
    if stream_type
      types << stream_type
    end
    types
  end

  def file_status(tab)
    case tab
    when "Unassigned"
      Constants.TRANSCRIPTION_FILE_STATUSES.upload.success
    end
  end

  def build_transcription_files(transcription_files)
    tasks = []
    transcription_files.each do |transcription_file|
      appellant_name = transcription_file.hearing.appeal.appellant_or_veteran_name
      file_number = transcription_file.hearing.appeal.veteran_file_number
      tasks << {
        id: transcription_file.id,
        docketNumber: transcription_file.docket_number,
        caseDetails: "#{appellant_name} (#{file_number})",
        types: transcription_file_types(transcription_file),
        hearingDate: hearing_date(transcription_file),
        hearingType: hearing_type(transcription_file),
        status: "Status"
      }
    end
    tasks
  end
end
