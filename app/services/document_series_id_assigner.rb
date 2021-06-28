# frozen_string_literal: true

##
# The series_id is the series_id provided by VBMS;
# otherwise, it is the document.vbms_document_id
# (aka `external_document_id` or `version_id` from eFolder;
#  aka `document_id` from VBMS).

class DocumentSeriesIdAssigner
  def initialize(appeal)
    @appeal = appeal
  end

  def call
    return unless documents_with_no_series_id.load.any?

    # This uses the activerecord-import gem to update the series_id of multiple
    # documents using a single SQL statement. This requires Postgres 9.5+.
    Document.import(documents_to_update, on_duplicate_key_update: [:series_id])
  end

  private

  attr_reader :appeal

  def documents_to_update
    documents_with_no_series_id.map do |document|
      vbms_document_id = document.vbms_document_id
      # We either map the vbms_document_id to a series_id, or we just copy the
      # vbms_document_id if we cannot find a mapping, since this means the
      # vbms_document_id is really a vva_id.
      document.series_id = document_id_to_series_hash[vbms_document_id] || vbms_document_id
      document
    end
  end

  def documents_with_no_series_id
    @documents_with_no_series_id ||= Document.where(file_number: appeal.veteran_file_number)
      .where(series_id: nil)
  end

  def document_id_to_series_hash
    @document_id_to_series_hash ||= begin
      result = {}
      document_series.each { |doc| result[doc.document_id] = doc.series_id }
      result
    end
  end

  def document_series
    @document_series ||= VBMSService.fetch_document_series_for(appeal).flatten
  end
end
