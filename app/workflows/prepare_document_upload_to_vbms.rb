# frozen_string_literal: true

class PrepareDocumentUploadToVbms
  include ActiveModel::Model

  validates :appeal_id, :file, presence: true
  validate :valid_document_type

  def initialize(params)
    @params = params.slice(:appeal_id, :document_type, :file)
    @document_type = @params[:document_type]
    @file = @params[:file]
  end

  def call
    @success = valid?
    if success
      document = VbmsUploadedDocument.create(document_params)
      UploadDocumentToVbmsJob.perform_later(document)
    end

    FormResponse.new(success: success, errors: [response_errors])
  end

  private

  attr_reader :document_type, :file, :params, :success

  def appeal_id
    Appeal.find_by(uuid: params[:appeal_id])&.id
  end

  def valid_document_type
    errors.add(:document_type, "is not recognized") unless Document.type_id(document_type)
  end

  def document_params
    {
      appeal_id: appeal_id,
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
end
