# frozen_string_literal: true

class WorkQueue::CorrespondenceDocumentSerializer
  include FastJsonapi::ObjectSerializer

  attribute :correspondence_id
  attribute :document_file_number
  attribute :pages
  attribute :vbms_document_id
  attribute :uuid
  attribute :document_type
  attribute :document_title do |object|
    doc_id = object.attributes["document_type"]
    Caseflow::DocumentTypes::TYPES[doc_id]
  end
end
