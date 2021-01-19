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

  # Fetch documents, then update and/or create them in the DB
  def find_or_create_documents!
    @find_or_create_documents ||= save!
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
    # Calls out to VBMSService.fetch_document_series_for(appeal)
    DocumentSeriesIdAssigner.new(appeal).call

    # Each document has a series_id and a version_id
    # (unfortunately we refer to version_id as vbms_document_id in most of the code)
    # See https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Reader#vbms
    vbms_doc_ver_ids = documents.map(&:vbms_document_id)

    existing_vbms_doc_ver_ids = Document.where(vbms_document_id: vbms_doc_ver_ids).pluck(:vbms_document_id)
    docs_to_update, docs_to_create = split_docs(documents, existing_vbms_doc_ver_ids)

    # Update existing docs
    updated_docs = Document.bulk_merge_and_save(docs_to_update)

    # Create new docs that don't exist
    Document.import(docs_to_create)

    # For newly created documents that have a series_id, copy over the metadata (annotations, tags, category labels)
    # from the latest version of the document (i.e., the latest id having the same series_id) in Caseflow.
    # The created document then becomes the latest version among the documents with the same series_id.
    series_id_docs = Document.where(vbms_document_id: docs_to_create.select(&:series_id).pluck(:vbms_document_id))
    copy_metadata_from_document(series_id_docs, vbms_doc_ver_ids)
    created_docs = retrieve_created_docs_including_nondb_attributes(docs_to_create)

    updated_docs + created_docs
  end

  def split_docs(documents, vbms_doc_ver_ids)
    documents.partition { |doc| vbms_doc_ver_ids.include?(doc.vbms_document_id) }
  end

  def copy_metadata_from_document(created_docs_with_series_id, vbms_doc_ver_ids)
    # Find the most recent saved document with the given series_id that is not in the list of vbms_doc_ver_ids passed
    # since vbms_doc_ver_ids have already been updated
    series_id_hash = Document.includes(:annotations, :tags)
      .where(series_id: created_docs_with_series_id.pluck(:series_id))
      .where.not(vbms_document_id: vbms_doc_ver_ids).group_by(&:series_id)
    created_docs_with_series_id.map do |document|
      # update the DB for each doc individually; this could be optimized if needed
      previous_documents = series_id_hash[document.series_id]&.sort_by(&:id)
      document.copy_metadata_from_document(previous_documents.last) if previous_documents.present?
    end
  end

  def retrieve_created_docs_including_nondb_attributes(docs_to_create)
    docs_to_create_hash = docs_to_create.index_by(&:vbms_document_id)
    created_docs = Document.where(vbms_document_id: docs_to_create.pluck(:vbms_document_id))
    created_docs.map do |doc|
      fetched_doc = docs_to_create_hash[doc.vbms_document_id]
      doc.assign_nondatabase_attributes(fetched_doc)
    end
  end

  def document_service
    @document_service ||= use_efolder ? EFolderService : VBMSService
  end

  def fetch_documents_from_service!
    doc_struct = document_service.fetch_documents_for(appeal, RequestStore.store[:current_user])

    self.documents = deduplicate(doc_struct[:documents], "fetched_documents")
    self.manifest_vbms_fetched_at = doc_struct[:manifest_vbms_fetched_at].try(:in_time_zone)
    self.manifest_vva_fetched_at = doc_struct[:manifest_vva_fetched_at].try(:in_time_zone)
  end

  # :reek:FeatureEnvy
  def deduplicate(docs, warning_message)
    dups_hash = docs.group_by(&:vbms_document_id).select { |_id, array| array.count > 1 }
    exact_dups_hash, nonexact_dups_hash = split_exact_dups(dups_hash)

    # Remove docs that are exact duplicates
    docs_to_remove = exact_dups_hash.map { |_id, array| array.drop(1) }.flatten
    docs -= docs_to_remove
    return docs if nonexact_dups_hash.empty?

    # Remove docs that are nonexact duplicates but have the same vbms_document_id
    # and also send a warning for investigation
    warn_about_same_vbms_document_id(warning_message, nonexact_dups_hash)
    docs_to_remove = nonexact_dups_hash.map { |_id, array| array.drop(1) }.flatten
    docs - docs_to_remove
  end

  # identify hash entries with an array consisting of the exact same document
  def split_exact_dups(dups_hash)
    dups_hash.partition { |_id, docs| docs.map(&:to_hash).uniq.size == 1 }
  end

  # :reek:FeatureEnvy
  def warn_about_same_vbms_document_id(warning_message, nonexact_dups_hash)
    docs_as_csv = nonexact_dups_hash.map { |_id, docs| docs.map { |doc| doc.to_hash.values.to_csv } }.flatten
    extra = { application: "reader",
              backtrace: caller,
              nonexact_dup_docs_count: nonexact_dups_hash.count,
              nonexact_dups_hash: nonexact_dups_hash,
              docs_as_csv: docs_as_csv.join("") }
    error_message = "Document records with duplicate vbms_document_id: #{warning_message}"
    Raven.capture_exception(DuplicateVbmsDocumentIdError.new(error_message), extra: extra)
  end

  class DuplicateVbmsDocumentIdError < RuntimeError; end
end
