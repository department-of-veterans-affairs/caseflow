# frozen_string_literal: true

class Hearings::TranscriptionPackagesController < ApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_transcription_user
  def transcription_package_tasks
    # Initial filter to get only the transcription packages with statuses 'Sent-Overdue' and 'Sent'
    @transcription_packages = TranscriptionPackage.with_status_overdue_or_sent
    apply_search
    apply_filters
    setup_pagination
    apply_sorting

    render json: {
      task_page_count: @total_pages,
      tasks: { data: build_package_json(@transcription_packages) },
      tasks_per_page: @page_size,
      total_task_count: @total_count
    }
  end

  def create_package
    result = TranscriptionPackages.new(transcription_pispatch_params).call
    count = transcription_pispatch_params[:hearings].count
    contractor = transcription_pispatch_params[:contractor_name]
    status = "#{count} transcription file#{count != 1 ? 's' : ''} to #{contractor}"

    if result
      title = "You have successfully assigned #{status}"
      message = ""
      type = "success"
    else
      title = "Unable to package #{status}"
      message = "All hearings in this work order will be returned to Unassigned queue"
      type = "error"
    end

    render json: {
      title: title,
      message: message,
      type: type
    }
  end

  def next_task_number
    task_number = TranscriptionPackage.next_task_number(current_user.id)

    existing_package = TranscriptionPackage.find_by_task_number(task_number)
    if !existing_package
      TranscriptionPackage.create!(
        task_number: task_number,
        created_by_id: current_user.id
      )
    end

    render json: { task_number: task_number }
  end

  def transcription_pispatch_params
    params
      .permit(:work_order_name,
              :sent_to_transcriber_date,
              :return_date,
              :contractor_name,
              hearings: [:hearing_id, :hearing_type])
  end

  def apply_search
    return if params[:search].blank?

    @transcription_packages = @transcription_packages.search(params[:search])
  end

  # rubocop:disable Metrics/MethodLength
  def apply_filters
    if params[:filter].present?
      params[:filter].each do |filter|
        filter_hash = Rack::Utils.parse_query(filter)
        if filter_hash["col"] == "dateSentColumn"
          @transcription_packages =
            @transcription_packages.filter_by_date(filter_hash["val"].split(","), "transcription_packages.created_at")
        end
        if filter_hash["col"] == "expectedReturnDateColumn"
          @transcription_packages =
            @transcription_packages.filter_by_date(filter_hash["val"].split(","), "expected_return_date")
        end
        if filter_hash["col"] == "contractorColumn"
          @transcription_packages =
            @transcription_packages.filter_by_contractor(filter_hash["val"].split("|"))
        end
        if filter_hash["col"] == "statusColumn"
          @transcription_packages =
            @transcription_packages.filter_by_status(filter_hash["val"].split("|"))
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def apply_sorting
    sort_by = params[:sort_by] || "id"
    order = params[:order] == "asc" ? "ASC" : "DESC"
    @transcription_packages =
      case sort_by
      when "dateSentColumn"
        @transcription_packages.order_by_field(order, "transcription_packages.created_at")
      when "expectedReturnDateColumn"
        @transcription_packages.order_by_field(order, "expected_return_date")
      when "contractorColumn"
        @transcription_packages.order_by_field(order, "transcription_contractors.name")
      else
        @transcription_packages.order_by_field(order, "transcription_packages.id")
      end
  end

  def setup_pagination
    current_page = (params[:page] || 1).to_i
    @page_size = (params[:page_size] || 15).to_i
    @page_start = (current_page - 1) * @page_size
    filtered_count = @transcription_packages.reselect("COUNT(transcription_packages.id) AS count_all")
    @total_count = filtered_count[0].count_all
    @total_pages = (@total_count / @page_size.to_f).ceil
    @transcription_packages = @transcription_packages
      .limit(@page_size)
      .offset(@page_start)
      .preload(:contractor, :transcriptions)
  end

  def build_package_json(transcription_packages)
    tasks = []
    transcription_packages.each do |transcription_package|
      tasks << {
        id: transcription_package.id,
        workOrder: transcription_package.task_number,
        items: transcription_package.contents_count,
        dateSent: transcription_package.created_at.to_formatted_s(:short_date),
        expectedReturnDate: transcription_package.expected_return_date.to_formatted_s(:short_date),
        contractor: transcription_package.contractor.name,
        status: transcription_package.status
      }
    end
    tasks
  end
end
