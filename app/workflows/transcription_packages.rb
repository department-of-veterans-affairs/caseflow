# frozen_string_literal: true

class TranscriptionPackages
  include ActiveModel::Model
  include ActiveModel::Validations

  include MailRequestValidator::Distribution
  include MailRequestValidator::DistributionDestination


  def initialize(work_order)
    @recipient_info = work_order
  end

  def call
    create_work_order
    create_zip_file
  end

  private

  def create_work_order
    # call job work_order
    Hearings::WorkOrderJob.perform(@recipient_info)
  end

  def create_zip_file
    # call job to create a zip File
    Hearings::ZipAndUploadTranscriptionFilesJob.perform(@recipient_info.hearings_list)
  end
end

