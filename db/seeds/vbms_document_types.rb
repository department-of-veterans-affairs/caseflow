# frozen_string_literal: true

module Seeds
  class VbmsDocumentTypes < Base
    def seed!
      create_document_types
    end

    private

    def create_document_types
      # Caseflow keeps track of VBMS Document Types at Caseflow::DocumentTypes::TYPES
      # https://github.com/department-of-veterans-affairs/caseflow-commons/blob/master/app/models/caseflow/document_types.rb

      # if VbmsDocumentType table is not empty we should only add the document types we are missing (recently added)
      # else the table is empty, so we should add all the document types
      # This is implemented this way so that if a new document type is added to the module,
      # we do not have to clear the table before running this seed file

      doc_types = []
      if VbmsDocumentType.count > 0
        doc_types = Caseflow::DocumentTypes::TYPES.reject { |key, _value| VbmsDocumentType.exists?(doc_type_id: key) }
      else
        Caseflow::DocumentTypes::TYPES.each do |key, _value|
          doc_types << VbmsDocumentType.new(doc_type_id: key)
        end
      end
      VbmsDocumentType.import(doc_types, validate: false) unless doc_types.empty?
    end
  end
end
