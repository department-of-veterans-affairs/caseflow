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
    puts ""
    puts 'call'
    puts work_order_params
    puts ""
    Hearings::WorkOrderFileJob.perform_now(work_order_params) ? create_zip_file : return
  end

  def create_zip_file
    puts ""
    puts 'create_zip_file'
    puts work_order_params
    puts ""
    Hearings::ZipAndUploadTranscriptionFilesJob.perform_now(work_order_params[:hearings]) ? create_bom_file : return
  end

  def create_bom_file
    puts ""
    puts 'create_bom_file'
    puts work_order_params
    puts ""
    Hearings::CreateBillOfMaterialsJob.perform_now(work_order_params) ? create_transcription_package : return
  end

  def create_transcription_package
    puts ""
    puts 'create_transcription_package'
    puts work_order_params
    puts ""
    Hearings::ZipAndUploadTranscriptionPackageJob.perform_now(work_order_params) ? upload_transcription_package : return
  end

  def upload_transcription_package
    puts ""
    puts 'upload_transcription_package'
    puts work_order_params
    puts ""
    Hearings::VaBoxUploadJob.perform_now(work_order_params, ENV["BOX_PARENT_FOLDER_ID"])
  end
end
