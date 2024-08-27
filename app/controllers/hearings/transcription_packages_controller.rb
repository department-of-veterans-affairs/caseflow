# frozen_string_literal: true

class Hearings::TranscriptionPackagesController < ApplicationController
  def show
    transcription_package = ::TranscriptionPackage.find_by(task_number: params[:task_number])
    return render json: { error_code: "Package not found" }, status: :not_found if transcription_package.nil?

    render json: Hearings::TranscriptionPackageSerializer.new(transcription_package).serializable_hash, status: :ok
  end

  def new
    work_order_params = params.permit(:work_order_name, :sent_to_transcriber_date, :return_date, :contractor_name, hearings: [:hearing_id, :hearing_type])
    transcription_package = TranscriptionPackages.new(work_order_params)

    if transcription_package.call
      render json: { message: "Work order processed successfully" }, status: :ok
    else
      render json: { error_code: "Failed to process work order" }, status: :unprocessable_entity
    end
  end
end
