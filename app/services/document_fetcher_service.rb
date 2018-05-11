class DocumentFetcherService
  include ActiveModel::Model

  attr_accessor :appeal, :use_efolder

  def documents
    fetch_documents_from_service!
    @documents
  end

  def number_of_documents
    documents.size
  end

  def manifest_vbms_fetched_at
    fetch_documents_from_service!
    @manifest_vbms_fetched_at
  end

  def manifest_vva_fetched_at
    fetch_documents_from_service!
    @manifest_vva_fetched_at
  end

  def find_or_create_documents!
    @created_documents ||= save!
  end

  private

  def save!
    AddSeriesIdToDocumentsJob.perform_now(@appeal)

    ids = documents.map(&:vbms_document_id)
    existing_documents = Document.where(vbms_document_id: ids)
      .includes(:annotations, :tags).each_with_object({}) do |document, accumulator|
      accumulator[document.vbms_document_id] = document
    end

    documents.map do |document|
      begin
        if existing_documents[document.vbms_document_id]
          document.merge_into(existing_documents[document.vbms_document_id]).save!
          existing_documents[document.vbms_document_id]
        else
          create_new_document!(document, ids)
        end
      rescue ActiveRecord::RecordNotUnique
        Document.find_by_vbms_document_id(document.vbms_document_id)
      end
    end
  end

  def create_new_document!(document, ids)
    document.save!

    # Find the most recent saved document with the given series_id that is not in the list of ids passed.
    previous_documents = Document.where(series_id: document.series_id).order(:id)
      .where.not(vbms_document_id: ids)

    if previous_documents.count > 0
      document.copy_metadata_from_document(previous_documents.last)
    end

    document
  end

  def fetch_documents_from_service!
    return if @documents

    document_service ||=
      if @use_efolder
        EFolderService
      else
        VBMSService
      end

    doc_struct = document_service.fetch_documents_for(@appeal, RequestStore.store[:current_user])

    @documents = doc_struct[:documents]
    @manifest_vbms_fetched_at = doc_struct[:manifest_vbms_fetched_at].try(:in_time_zone)
    @manifest_vva_fetched_at = doc_struct[:manifest_vva_fetched_at].try(:in_time_zone)
  end
end
