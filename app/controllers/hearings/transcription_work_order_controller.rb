# frozen_string_literal: true

class Hearings::TranscriptionWorkOrderController < ApplicationController
  include HearingsConcerns::VerifyAccess
  before_action :set_task_number

  def display_wo_summary
    wo_summary = ::TranscriptionWorkOrder.display_wo_summary(@task_number)
    respond_to do |format|
      format.html { render "hearings/index" }
      format.json { render json: { data: wo_summary } }
    end
  end

  def display_wo_contents
    wo_content = ::TranscriptionWorkOrder.display_wo_contents(@task_number)
    if wo_content.present?
      render json: { data: wo_content }
    else
      render_error("Transcription content not found.", :not_found)
    end
  end

  def unassign_wo
    begin
      wo_content = ::TranscriptionWorkOrder.unassign_wo(@task_number)
      render json: { data: wo_content }
    rescue StandardError => error
      Rails.logger.error("Failed to unassign work order: #{error.message}")
      render_error("Something went wrong.", :internal_server_error)
    end
  end

  def unassigning_work_order
    begin
      Transcription.unassign_by_task_number(@task_number)
      TranscriptionPackage.cancel_by_task_number(@task_number)
      TranscriptionFile.reset_files(@task_number)
    rescue StandardError => error
      Rails.logger.error(
        "Error in unassigning work order for task number #{@task_number}: #{error.message}"
      )
    end
  end

  private

  def set_task_number
    @task_number = params[:taskNumber]
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
