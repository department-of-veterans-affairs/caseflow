# frozen_string_literal: true

class NewDocumentsForUser
  include ActiveModel::Model

  attr_accessor :appeal, :user, :query_vbms, :date_to_compare_with

  # Retrieves any documents that have been uploaded more recently than the user has viewed
  # the appeal or an optional provided date. Try to load docs from caseflow if query_vbms is
  # false, load from vbms otherwise
  def process!
    caseflow_documents = find_or_create_documents
    appeal_view = appeal.appeal_views.find_by(user: user)

    return caseflow_documents if !appeal_view && !date_to_compare_with

    @date_to_compare_with ||= Time.zone.at(0)
    compare_date = appeal_view ? [date_to_compare_with, appeal_view.last_viewed_at].max : date_to_compare_with

    filter_docs_by_date(caseflow_documents, compare_date)
  end

  private

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
