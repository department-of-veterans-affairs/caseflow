# frozen_string_literal: true

class Hearings::TranscriptionsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  before_action :verify_transcription_user

  def next_transcription
    transcription = Transcription.first_empty_transcription_file
    render json: { id: transcription&.id, task_id: transcription&.task_id }
  end

  # Temporary action for testing
  def package_files
    Transcription.find_by(id: params[:id], transcription_status: "unassigned")
      .update(transcription_status: "assigned")
    Transcription.create!(created_by_id: User.system_user.id,
                          task_id: params[:task_id],
                          transcription_status: "unassigned")
    render json: { message: "files packaged successfully" }, status: :accepted
  end
end
