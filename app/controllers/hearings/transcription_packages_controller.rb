# frozen_string_literal: true

class Hearings::TranscriptionPackagesController < ApplicationController
  def show
    transcription_package = TranscriptionPackage.find_by(params[:task_number])
    return render json: { error_code: "Package not found" }, status: :not_found if transcription_package.nil?

    render json: Hearings::TranscriptionPackagesSerializer.new(transcription_package).serializable_hash, status: :ok
  end
end
