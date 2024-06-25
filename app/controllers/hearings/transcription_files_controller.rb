# frozen_string_literal: true

class Hearings::TranscriptionFilesController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_hearings, only: [:download_transcription_file]
  before_action :verify_transcription_user, only: [:transcription_file_tasks]

  def download_transcription_file
    tmp_location = file.fetch_file_from_s3!
    File.open(tmp_location, "r") { |stream| send_data stream.read, filename: file.file_name }
    file.clean_up_tmp_location
  end

  def transcription_file_tasks
    @transcription_files = TranscriptionFile.filterable_values
    select_based_on_tab
    apply_filters
    setup_pagination
    apply_sorting
    render json: {
      task_page_count: @total_pages,
      tasks: { data: build_transcription_json(@transcription_files) },
      tasks_per_page: @page_size,
      total_task_count: @total_count
    }
  end

  def locked
    locked_files = TranscriptionFile.locked
    files = []
    locked_files.each do |file|
      status = file.locked_by_id == current_user.id ? "selected" : "locked"
      username = file.try(:locked_by).try(:username)
      message = status == "locked" && username ? "Locked by " + username : ""
      files << { id: file.id, status: status, message: message }
    end
    render json: files
  end

  def lock
    files = TranscriptionFile.where(id: params[:file_ids])
    status = params[:status] && params[:status].to_s == "true" ? true : false
    lockable_file_ids = []
    files.each do |file|
      if file.lockable?(current_user.id)
        lockable_file_ids << file.id
      end
    end

    if status
      locked_by_id = current_user.id
      locked_at = Time.now.utc
    else
      locked_by_id = nil
      locked_at = nil
    end

    TranscriptionFile.where(id: lockable_file_ids).update_all(locked_by_id: locked_by_id, locked_at: locked_at)

    locked
  end

  private

  def file
    @file ||= TranscriptionFile.find(params[:file_id])
  end

  def select_based_on_tab
    if params[:tab] == "Unassigned"
      @transcription_files = @transcription_files.unassigned
    end
  end

  def apply_filters
    if params[:filter].present?
      params[:filter].each do |filter|
        filter_hash = Rack::Utils.parse_query(filter)
        if filter_hash["col"] == "hearingTypeColumn"
          @transcription_files = @transcription_files.filter_by_hearing_type(filter_hash["val"].split("|"))
        end
        if filter_hash["col"] == "typesColumn"
          @transcription_files = @transcription_files.filter_by_types(filter_hash["val"].split("|"))
        end
      end
    end
  end

  def apply_sorting
    sort_by = params[:sort_by] || "id"
    order = params[:order] == "asc" ? "ASC" : "DESC"
    @transcription_files =
      case sort_by
      when "hearingDateColumn"
        @transcription_files.order_by_hearing_date(order)
      when "hearingTypeColumn"
        @transcription_files.order_by_hearing_type(order)
      when "typesColumn"
        @transcription_files.order_by_case_type(order)
      else
        @transcription_files.order_by_id(order)
      end
  end

  def setup_pagination
    current_page = (params[:page] || 1).to_i
    @page_size = (params[:page_size] || 15).to_i
    @page_start = (current_page - 1) * @page_size
    filtered_count = @transcription_files.reselect("COUNT(transcription_files.id) AS count_all")
    @total_count = filtered_count[0].count_all
    @total_pages = (@total_count / @page_size.to_f).ceil
    @transcription_files = @transcription_files
      .limit(@page_size)
      .offset(@page_start)
      .preload(hearing: [:hearing_day, :appeal])
  end

  def build_transcription_json(transcription_files)
    tasks = []
    transcription_files.each do |transcription_file|
      tasks << {
        id: transcription_file.id,
        externalAppealId: transcription_file.external_appeal_id,
        docketNumber: transcription_file.docket_number,
        caseDetails: transcription_file.case_details,
        isAdvancedOnDocket: transcription_file.advanced_on_docket?,
        caseType: transcription_file.case_type,
        hearingDate: transcription_file.hearing_date,
        hearingType: transcription_file.hearing_type,
        fileStatus: transcription_file.file_status
      }
    end
    tasks
  end
end
