# frozen_string_literal: true

class TranscriptionPackages
  include ActiveModel::Model
  include ActiveModel::Validations

  include MailRequestValidator::Distribution
  include MailRequestValidator::DistributionDestination

  attr_reader :work_order_params

  def initialize(work_order_params)
    @work_order_params = work_order_params
  end

  def call
    Hearings::WorkOrderFileJob.perform_now(work_order_params) ? create_zip_file : return
  end

  def create_zip_file
    Hearings::ZipAndUploadTranscriptionFilesJob.perform_now(work_order_params[:hearings]) ? create_bom_file : return
  end

  def create_bom_file
    Hearings::CreateBomFileJob.perform_now(work_order_params) ? zip_and_upload_transcription_package : return
  end

  def zip_and_upload_transcription_package
    transcription_package = Hearings::ZipAndUploadTranscriptionPackageJob.perform_now(work_order_params)
    if transcription_package.is_a?(TranscriptionPackage)
      upload_transcription_package(transcription_package)
    end
  end

  def upload_transcription_package(transcription_package)
    Hearings::VaBoxUploadJob.perform_now(transcription_package)
  end
end
