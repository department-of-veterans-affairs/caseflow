# frozen_string_literal: true

class Hearings::TranscriptionsController < ApplicationController
  include HearingsConcerns::VerifyAccess

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
  before_action :verify_transcription_user

  def next_transcription
    transcription = Transcription.first_empty_transcription_file
    render json: { id: transcription&.id, task_id: transcription&.task_id }
  end
end
