# frozen_string_literal: true

module DocumentConcern
  extend ActiveSupport::Concern

  # Number of documents stored locally via nightly RetrieveDocumentsForReaderJob.
  # Fall back to count from VBMS if no local documents are found.
  def number_of_documents_from_caseflow
    count = Document.where(file_number: veteran_file_number).size
    (count != 0) ? count : number_of_documents
  end
end
