module DocumentConcern
  extend ActiveSupport::Concern

  # Number of documents stored locally via nightly RetrieveDocumentsForReaderJob.
  # Fall back to count from VBMS if no local documents are found.
  def number_of_documents_from_caseflow
    count = Document.where(file_number: veteran_file_number).size
    (count != 0) ? count : number_of_documents
  end

  def new_documents_from_caseflow(user)
    caseflow_documents = Document.where(file_number: veteran_file_number)
    return new_documents_for_user(user) if caseflow_documents.empty?

    appeal_view = appeal_views.find_by(user: user)
    return caseflow_documents if !appeal_view

    caseflow_documents.select do |doc|
      next if doc.upload_date.nil?

      doc.upload_date > appeal_view.last_viewed_at
    end
  end

end