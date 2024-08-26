# frozen_string_literal: true

class Hearings::WorkOrderPackagesController < ApplicationController
  include HearingsConcerns::VerifyAccess
  before_action :set_task_number

  def display_wo_summary
    wo_summary = ::ManageTranscriptionPackage.display_wo_summary(@task_number)
    if wo_summary.present?
      render json: { data: wo_summary }
    else
      render_error("Transcription summary not found.", :not_found)
    end
  end

  def display_wo_contents
    wo_content = ::ManageTranscriptionPackage.display_wo_contents(@task_number)
    if wo_content.present?
      render json: { data: wo_content }
    else
      render_error("Transcription content not found.", :not_found)
    end
  end

  def unassign_wo
    begin
      wo_content = ::ManageTranscriptionPackage.unassign_wo(@task_number)
      render json: { data: wo_content }
    rescue StandardError => error
      Rails.logger.error("Failed to unassign work order: #{error.message}")
      render_error("Something went wrong.", :internal_server_error)
    end
  end

  private

  def set_task_number
    @task_number = params[:task_number]
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
