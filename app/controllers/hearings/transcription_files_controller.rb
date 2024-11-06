# frozen_string_literal: true

class Hearings::TranscriptionFilesController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_page_not_found
  before_action :verify_access_to_hearings, only: [:download_transcription_file]
  before_action :verify_transcription_user, only: [:transcription_file_tasks]

  # Downloads file and sends to user's local computer
  def download_transcription_file
    tmp_location = file.fetch_file_from_s3!
    File.open(tmp_location, "r") { |stream| send_data stream.read, filename: file.file_name }
    file.clean_up_tmp_location
  end

  def render_page_not_found
    redirect_to "/404"
  end

  def transcription_file_tasks
    @transcription_files = Hearings::TranscriptionFile.filterable_values
    select_based_on_tab
    apply_search
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
    locked_files = Hearings::TranscriptionFile.locked.preload(:locked_by)
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
    files = Hearings::TranscriptionFile.where(id: params[:file_ids])
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

    Hearings::TranscriptionFile.where(id: lockable_file_ids).update_all(
      locked_by_id: locked_by_id, locked_at: locked_at
    )

    locked
  end

  def format_docket_number(file)
    if file.hearing_type == "Hearing"
      return "H" + file.docket_number
    end

    "L" + file.docket_number
  end

  def selected_files_info
    files = []
    ids = params[:file_ids].split(",")
    Hearings::TranscriptionFile.where(id: ids).filterable_values.each do |transcription_file|
      hearing = transcription_file.hearing
      files << {
        id: transcription_file.id,
        docketNumber: format_docket_number(transcription_file),
        firstName: hearing.appeal.appellant_first_name,
        lastName: hearing.appeal.appellant_last_name,
        isAdvancedOnDocket: transcription_file.advanced_on_docket?,
        caseType: transcription_file.case_type,
        hearingDate: transcription_file.hearing_date,
        appealType: transcription_file.hearing_type == "Hearing" ? "AMA" : "Legacy",
        judge: hearing.judge&.full_name&.split(" ")&.last,
        regionalOffice: hearing.regional_office&.city,
        hearingId: hearing.id
      }
    end
    render json: files
  end

  def fetch_file
    docket_number = params[:docket_number]
    file_path = Hearings::TranscriptionFile.fetch_file_by_docket_and_type(docket_number)

    if file_path
      send_file file_path, filename: File.basename(file_path), type: "application/vnd.ms-excel"
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end

  private

  def file
    @file ||= Hearings::TranscriptionFile.find(params[:file_id])
  end

  def select_based_on_tab
    case params[:tab]
    when "Unassigned"
      @transcription_files = @transcription_files.unassigned
    when "Completed"
      @transcription_files = @transcription_files.completed
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
        if filter_hash["col"] == "hearingDateColumn"
          @transcription_files = @transcription_files.filter_by_hearing_dates(filter_hash["val"].split(","))
        end
        if filter_hash["col"] == "statusColumn"
          @transcription_files = @transcription_files.filter_by_status(filter_hash["val"].split("|"))
        end
      end
    end
  end

  def apply_search
    return if params[:search].blank?

    @transcription_files = @transcription_files.search(params[:search])
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
      task = {
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
      task = add_completed_tab_fields(task, transcription_file) if params[:tab] == "Completed"
      task = add_all_tab_fields(task, transcription_file) if params[:tab] == "All"
      tasks << task
    end
    tasks
  end

  def add_completed_tab_fields(task, transcription_file)
    task.merge(
      {
        workOrder: transcription_file.transcription&.task_number,
        expectedReturnDate: transcription_file&.transcription&.transcription_package
          &.expected_return_date&.to_formatted_s(:short_date),
        returnDate: transcription_file.date_returned_box&.to_formatted_s(:short_date),
        contractor: transcription_file&.transcription&.transcription_package&.contractor&.name
      }
    )
  end

  def add_all_tab_fields(task, transcription_file)
    task.merge(
      {
        workOrder: transcription_file.transcription&.task_number,
        uploadDate: transcription_file&.date_returned_box&.to_formatted_s(:short_date),
        returnDate: transcription_file.date_returned_box&.to_formatted_s(:short_date),
        contractor: transcription_file&.transcription&.transcription_package&.contractor&.name
      }
    )
  end
end
