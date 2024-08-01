# frozen_string_literal: true

# The Purpose of this file is to fix the codeclimate issues.
class DocumentManager
  def self.create_correspondence_document(correspondence, veteran, doc_type)
    CorrespondenceDocument.find_or_create_by!(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: doc_type[:id],
      document_type: doc_type[:id],
      pages: rand(1..30),
      correspondence_id: correspondence.id
    )

    # This is a placeholder until CorrespondenceDocuments are available via the CMP integration.
    Document.find_or_create_by!(
      vbms_document_id: doc_type[:id]
    )
  end
end
