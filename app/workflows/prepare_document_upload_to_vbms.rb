# frozen_string_literal: true

class PrepareDocumentUploadToVbms
  include ActiveModel::Model

  validates :veteran_file_number, :file, presence: true
  validate :valid_document_type

  def initialize(params, user)
    @params = params.slice(:veteran_file_number, :document_type, :file)
    @document_type = @params[:document_type]
    @user = user
  end

  def call
    success = valid?
    if success
      throw_error_if_file_number_not_match_bgs
      VbmsUploadedDocument.create(document_params).tap do |document|
        document.cache_file
        UploadDocumentToVbmsJob.perform_later(document_id: document.id, initiator_css_id: user.css_id)
      end
    end

    FormResponse.new(success: success, errors: [response_errors])
  end

  private

  attr_accessor :success
  attr_reader :document_type, :params, :user

  def veteran_file_number
    @veteran_file_number = @params[:veteran_file_number]
  end

  def file
    @params[:file]
  end

  def valid_document_type
    errors.add(:document_type, "is not recognized") unless Document.type_id(document_type)
  end

  def document_params
    {
      appeal_id: appeal.id,
      appeal_type: appeal.class.name,
      document_type: document_type,
      file: file
    }
  end

  def response_errors
    return if success

    {
      message: errors.full_messages.join(", ")
    }
  end

  def throw_error_if_file_number_not_match_bgs
    unless veteran.file_number == BGSService.new.fetch_file_number_by_ssn(veteran.ssn)
      fail(
        Caseflow::Error::BgsFileNumberMismatch,
        appeal_id: appeal.id, user_id: user.id
      )
    end
  end
end
