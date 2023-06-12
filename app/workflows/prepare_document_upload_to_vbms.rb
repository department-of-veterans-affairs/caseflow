# frozen_string_literal: true

class PrepareDocumentUploadToVbms
  include ActiveModel::Model

  validates :veteran_file_number, :file, presence: true
  validate :valid_document_type

  # Params: params - hash containing file and document_type at minimum
  #         user - current user that is preparing the document for upload
  #         appeal - Appeal object (optional if ssn or file number are passed into params)
  #         communication_package - Payload with copies value (integer) and distributions value (array of
  #           MailRequest objects) to be submitted to Package Manager if optional recipient info is present

  def initialize(params, user, appeal = nil, communication_package = nil)
    @params = params.slice(:veteran_file_number, :document_type, :document_subject, :document_name, :file, :application)
    @params[:communication_package] = communication_package unless communication_package.nil?
    @user = user
    @appeal = appeal
  end

  # Purpose: Queues a job to upload a document to vbms
  #
  # Params: See initialize
  #
  # Return: nil
  def call
    success = valid?
    if success
      @params[:veteran_file_number] = throw_error_if_file_number_not_match_bgs
      VbmsUploadedDocument.create(document_params).tap do |document|
        document.cache_file
        UploadDocumentToVbmsJob.perform_later(upload_document_job_params(document))
      end
    end

    FormResponse.new(success: success, errors: [response_errors])
  end

  private

  attr_accessor :success
  attr_reader :params, :user

  def veteran_file_number
    @params[:veteran_file_number]
  end

  def document_subject
    @params[:document_subject]
  end

  def document_name
    @params[:document_name]
  end

  def file
    @params[:file]
  end

  def document_type
    @params[:document_type]
  end

  def valid_document_type
    errors.add(:document_type, "is not recognized") unless Document.type_id(document_type)
  end

  def bgs_service
    @bgs_service || BGSService.new
  end

  def veteran_ssn
    (!@appeal.nil? && !@appeal.veteran_ssn.nil? && !@appeal.veteran_ssn.empty?) ? @appeal.veteran_ssn : nil
  end

  def document_params
    {
      appeal_id: @appeal&.id,
      appeal_type: @appeal&.class&.name,
      veteran_file_number: veteran_file_number,
      document_name: document_name,
      document_subject: document_subject,
      document_type: document_type,
      file: file
    }
  end

  def communication_package
    return nil if params[:communication_package].blank?

    params[:communication_package]
  end

  def upload_document_job_params(document)
    {
      document_id: document.id,
      initiator_css_id: @user.css_id,
      application: @params[:application],
      communication_package: communication_package.to_json
    }
  end

  def response_errors
    return if success

    {
      message: errors.full_messages.join(", ")
    }
  end

  def throw_error_if_file_number_not_match_bgs
    bgs_file_number = nil
    if !veteran_file_number.nil?
      bgs_file_number = bgs_service.fetch_file_number_by_ssn(veteran_ssn)
    end
    if bgs_service.fetch_veteran_info(veteran_file_number).nil?
      if !bgs_file_number.blank? && !bgs_service.fetch_veteran_info(bgs_file_number).nil?
        bgs_file_number
      else
        fail(
          Caseflow::Error::BgsFileNumberMismatch,
          file_number: veteran_file_number, user_id: user.id
        )
      end
    else
      veteran_file_number
    end
  end
end
