module DocumentConcern
  extend ActiveSupport::Concern

  # Number of documents stored locally via nightly RetrieveDocumentsForReaderJob.
  # Fall back to count from VBMS if no local documents are found.
  def number_of_documents_from_caseflow
    count = Document.where(file_number: veteran_file_number).size
    (count != 0) ? count : number_of_documents
  end

  # Retrieves any documents that have been uploaded more recently than the user has viewed
  # the appeal or an optional provided date
  def new_documents_from_caseflow(user, alt_date_timestamp = nil)
    caseflow_documents = Document.where(file_number: veteran_file_number)
    return new_documents_for_user(user, alt_date_timestamp) if caseflow_documents.empty?

    appeal_view = appeal_views.find_by(user: user)
    return caseflow_documents if !appeal_view && !alt_date_timestamp

    alt_date = alt_date_timestamp ? DateTime.strptime(alt_date_timestamp, "%s") : Time.zone.at(0)
    compare_date = appeal_view ? [alt_date, appeal_view.last_viewed_at].max : alt_date

    filter_docs_by_date(caseflow_documents, compare_date)
  end

  def filter_docs_by_date(documents, date)
    documents.select do |doc|
      next if doc.upload_date.nil?

      doc.upload_date > date
    end
  end
end
