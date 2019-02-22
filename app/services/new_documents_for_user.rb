class NewDocumentsForUser
  include ActiveModel::Model

  attr_accessor :appeal, :user, :query_vbms, :date_to_compare_with

  def initialize(attributes)
    super(attributes)
  end

  def process!
    caseflow_documents = find_or_create_documents
    appeal_view = appeal.appeal_views.find_by(user: user)

    return caseflow_documents if !appeal_view && !date_to_compare_with

    compare_date = appeal_view ? [date_to_compare_with, appeal_view.last_viewed_at].max : date_to_compare_with

    filter_docs_by_date(caseflow_documents, compare_date)
  end

  def filter_docs_by_date(documents, date)
    documents.select do |doc|
      next if doc.upload_date.nil?

      doc.upload_date > date
    end
  end

  def find_or_create_documents
    docs = Document.where(file_number: appeal.veteran_file_number)

    return docs if !query_vbms && docs.present?

    # Otherwise, fetch documents from VBMS and save in Caseflow
    appeal.document_fetcher.find_or_create_documents!
    Document.where(file_number: appeal.veteran_file_number)
  end
end
