class DocumentService
  def initialize(appeal, use_efolder: false)
    @appeal = appeal
    @use_efolder = use_efolder
  end

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
    @manifest_vbms_fetched_at
  end

  def find_or_create!
    @created_documents ||= save!
  end

  private

  def save!
    return find_or_create_documents_v2! if FeatureToggle.enabled?(:efolder_api_v2,
                                                                  user: RequestStore.store[:current_user])
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
          document.save!
          document
        end
      rescue ActiveRecord::RecordNotUnique
        Document.find_by_vbms_document_id(document.vbms_document_id)
      end
    end
  end

  def save_v2!
    AddSeriesIdToDocumentsJob.perform_now(self)

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
