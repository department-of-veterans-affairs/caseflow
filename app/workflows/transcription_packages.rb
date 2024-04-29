# frozen_string_literal: true

class TranscriptionPackages
  include ActiveModel::Model
  include ActiveModel::Validations

  include MailRequestValidator::Distribution
  include MailRequestValidator::DistributionDestination


  def initialize(work_order)
    @recipient_info = work_order
    @wo = nil
    @zipf = nil
  end

  def call
    if valid?
      @wo = create_work_order
      @zipf = create_zipFile
    else
      fail Caseflow::Error::MissingRecipientInfo
    end
  end

  private

  def create_work_order
    # call job work_order
    Hearings::WorkOrderJob.perform(recipient_params_parse)
  end

  def create_zipFile
    # call job to create a zip File
    Hearings::ZipAndUploadTranscriptionFilesJob.perform(recipient_params_parse)
  end

  def recipient_params_parse
    {
      work_order: work_oder,
      return_date: return_date,
      contractor: contractor,
      hearing_list: hearing_list
    }
  end

  def work_oder
    @recipient_info[:work_order_name]
  end

  def return_date
    @recipient_info[:return_date]
  end

  def contractor
    @recipient_info[:contractor]
  end

  def hearing_list
    @recipient_info[:hearings]
  end

end

