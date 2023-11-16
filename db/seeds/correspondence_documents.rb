module Seeds
  class CorrespondenceDocuments < Base
    def seed!
      create_correspondence_documents
    end

    private

    # rubocop:disable Metrics/LineLength
    def create_correspondence_documents
      (1..10).each do |id|
        CorrespondenceDocument.find_or_create_by(correspondence_id: id, document_type: 719, pages: 20, vbms_document_id: "1")
        CorrespondenceDocument.find_or_create_by(correspondence_id: id, document_type: 672, pages: 10, vbms_document_id: "1")
        CorrespondenceDocument.find_or_create_by(correspondence_id: id, document_type: 18, pages: 5, vbms_document_id: "1")
      end
    end
    # rubocop:enable Metrics/LineLength
  end
end
