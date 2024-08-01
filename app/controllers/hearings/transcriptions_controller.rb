# frozen_string_literal: true

class Hearings::TranscriptionsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  before_action :verify_transcription_user

  def next_transcription_task_id
    render json: { task_id: Transcription.first_empty_transcription_file&.task_id }
  end
end
