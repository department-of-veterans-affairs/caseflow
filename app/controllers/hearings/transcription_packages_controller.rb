# frozen_string_literal: true

class Hearings::TranscriptionPackagesController < ApplicationController
  def show
    transcription_package = ::TranscriptionPackage.find_by(task_number: params[:task_number])
    return render json: { error_code: "Package not found" }, status: :not_found if transcription_package.nil?

    render json: Hearings::TranscriptionPackageSerializer.new(transcription_package).serializable_hash, status: :ok
  end

  def new
    # todo
    Rails.logger.info("Work order #{params['work_order_name']} submitted")
  end
end
