# frozen_string_literal: true
# Create correspondence type seeds

module Seeds
  class VbmsDocumentTypes < Base
    def seed!
      create_document_types
    end

    private

    def create_document_types
      VbmsDocumentType.find_or_create_by(doc_type_id: 48)
    end
  end
end
