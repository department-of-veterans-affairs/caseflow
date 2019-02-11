class AddSeriesIdToDocumentsService < ApplicationJob
  queue_as :low_priority

  def self.add_series_ids(appeal)
    documents_to_check = Document.where(file_number: appeal.veteran_file_number).where(series_id: nil)

    if documents_to_check.load.any?
      document_series = VBMSService.fetch_document_series_for(appeal)

      version_to_series_hash = document_series.reduce({}) do |map, document_versions|
        map.merge(
          document_versions.reduce({}) do |inner_map, document|
            inner_map.merge(document["document_id"] => document["series_id"])
          end
        )
      end

      documents_to_check.each do |document|
        # We either map the vbms_document_id to a series_id, or we just copy the vbms_document_id if we
        # cannot find a mapping, since this means the vbms_document_id is really a vva_id.
        document.update!(series_id: version_to_series_hash[document.vbms_document_id] || document.vbms_document_id)
      end
    end
  end
end
