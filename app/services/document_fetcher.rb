# frozen_string_literal: true

class DocumentFetcher
  include ActiveModel::Model

  attr_accessor :appeal, :use_efolder

  def initialize(attributes)
    super(attributes)
    fetch_documents_from_service!
  end

  attr_accessor :documents
  attr_reader :manifest_vbms_fetched_at, :manifest_vva_fetched_at

  def number_of_documents
    documents.size
  end

  def find_or_create_documents!
    @find_or_create_documents ||= save!
  end

  def document_service
    @document_service ||= use_efolder ? EFolderService : VBMSService
  end

  private

  # Expect appeal.manifest_(vva|vbms)_fetched_at to be either nil or a Time objects
  def manifest_vbms_fetched_at=(fetched_at)
    @manifest_vbms_fetched_at = fetched_at.strftime(fetched_at_format) if fetched_at
  end

  def manifest_vva_fetched_at=(fetched_at)
    @manifest_vva_fetched_at = fetched_at.strftime(fetched_at_format) if fetched_at
  end

  def fetched_at_format
    "%D %l:%M%P %Z %z"
  end

  def save!
    DocumentSeriesIdAssigner.new(appeal).call

    ids = documents.map(&:vbms_document_id)
    existing_documents = Document.where(vbms_document_id: ids)
      .includes(:annotations, :tags).each_with_object({}) do |document, accumulator|
      accumulator[document.vbms_document_id] = document
    end

    documents.map do |document|
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

  def create_new_document!(document, ids)
    document.save!

    if document.series_id
      # Find the most recent saved document with the given series_id that is not in the list of ids passed.
      previous_documents = Document.where(series_id: document.series_id).order(:id)
        .where.not(vbms_document_id: ids)

      if previous_documents.any?
        document.copy_metadata_from_document(previous_documents.last)
      end
    end

    document
  end

  def fetch_documents_from_service!
    doc_struct = document_service.fetch_documents_for(appeal, RequestStore.store[:current_user])

    self.documents = doc_struct[:documents]
    self.manifest_vbms_fetched_at = doc_struct[:manifest_vbms_fetched_at].try(:in_time_zone)
    self.manifest_vva_fetched_at = doc_struct[:manifest_vva_fetched_at].try(:in_time_zone)
  end
end
