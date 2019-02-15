module DocumentConcern
  extend ActiveSupport::Concern

  # Number of documents stored locally via nightly RetrieveDocumentsForReaderJob.
  # Fall back to count from VBMS if no local documents are found.
  def number_of_documents_from_caseflow
    count = Document.where(file_number: veteran_file_number).size
    (count != 0) ? count : number_of_documents
  end

  # Retrieves any documents that have been uploaded more recently than the user has viewed
  # the appeal or an optional provided date. Try to load docs from caseflow if cached is
  # true, load from vbms otherwise
  def new_documents_for_user(user:, cached: true, placed_on_hold_at: nil)
    caseflow_documents = find_or_create_documents(cached)

    appeal_view = appeal_views.find_by(user: user)
    return caseflow_documents if !appeal_view && !placed_on_hold_at

    placed_on_hold_at = placed_on_hold_at ? DateTime.strptime(placed_on_hold_at, "%s") : Time.zone.at(0)
    compare_date = appeal_view ? [placed_on_hold_at, appeal_view.last_viewed_at].max : placed_on_hold_at

    filter_docs_by_date(caseflow_documents, compare_date)
  end

  def filter_docs_by_date(documents, date)
    documents.select do |doc|
      next if doc.upload_date.nil?

      doc.upload_date > date
    end
  end

  def find_or_create_documents(cached)
    caseflow_documents = Document.where(file_number: veteran_file_number)

    return caseflow_documents if cached || caseflow_documents.present?

    # Otherwise, fetch documents from VBMS and save in Caseflow
    document_fetcher.find_or_create_documents!
    Document.where(file_number: veteran_file_number)
  end
end
