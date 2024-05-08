# frozen_string_literal: true

module Seeds
  class UpdateCorrespondenceNod < Base
    def seed!
      update_correspondence_nod
    end

    def update_correspondence_nod
      correspondences = ::Correspondence.all
      correspondences.each do |correspondence|
        nod = correspondence.correspondence_documents.any? do |doc|
          Caseflow::DocumentTypes::TYPES[doc["vbms_document_type_id"]].include?("10182")
        end
        correspondence.nod = nod
        correspondence.save(validate: false)
      end
    end
  end
end
