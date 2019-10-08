# frozen_string_literal: true

class DocumentsFromVbmsDocuments
  def initialize(documents:, file_number:)
    @documents = documents
    @file_number = file_number
  end

  def call
    documents.map { |vbms_document| Document.from_vbms_document(vbms_document, file_number) }
  end

  private

  attr_reader :documents, :file_number
end
