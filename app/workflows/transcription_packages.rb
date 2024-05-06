# frozen_string_literal: true

class TranscriptionPackages
  include ActiveModel::Model
  include ActiveModel::Validations

  include MailRequestValidator::Distribution
  include MailRequestValidator::DistributionDestination

  def initialize(work_order_params)
    @work_order_params = work_order_params
  end

  def call
    create_work_order
    create_zip_file
    create_BoM_file
    create_transcription_package
    upload_transcription_package
  end

  private

  def create_work_order
    # call job work_order
    Hearings::WorkOrderFileJob.perform_now(@work_order_params)
  end

  def create_zip_file
    # call job to create a zip File
    Hearings::ZipAndUploadTranscriptionFilesJob.perform_now(@work_order_params.hearings)
  end

  def create_BoM_file
    # TODO -- call to job
  end

  def create_transcription_package
    # TODO -- call to job
  end

  def upload_transcription_package
    # TODO -- call to job
  end
end

