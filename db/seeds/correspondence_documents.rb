module Seeds
  class CorrespondenceDocuments < Base
    def seed!
      create_correspondence_documents
    end

    private

    def create_correspondence_documents
        CorrespondenceDocument.find_or_create_by(correspondence_id: 1, document_type: 1234, pages: 20, vbms_document_id: 1)
    end
  end
end