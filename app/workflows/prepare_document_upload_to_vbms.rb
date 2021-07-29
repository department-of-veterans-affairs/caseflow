# frozen_string_literal: true

class PrepareDocumentUploadToVbms
  include ActiveModel::Model

  validates :appeal, :file, presence: true
  validate :valid_document_type

  def initialize(params, user)
    @params = params.slice(:appeal_id, :document_type, :file)
    @document_type = @params[:document_type]
    @file = @params[:file]
    @user = user
  end

  def call
    @success = valid?
    if success
      VbmsUploadedDocument.create(document_params).tap do |document|
        document.cache_file
        UploadDocumentToVbmsJob.perform_later(document_id: document.id, initiator_css_id: user.css_id)
      end
    end

    FormResponse.new(success: success, errors: [response_errors])
  end

  private

  attr_reader :document_type, :file, :params, :success, :user

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
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
end
