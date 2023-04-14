# frozen_string_literal: true

class Fakes::ClaimEvidenceService
  class << self

    def document_types
      JSON.parse(IO.binread(File.join(Rails.root, "lib", "fakes", "data", "DOCUMENT_TYPES.json")))["documentTypes"]
    end

    def alt_document_types
      JSON.parse(IO.binread(File.join(Rails.root, "lib", "fakes", "data", "DOCUMENT_TYPES.json")))["alternativeDocumentTypes"]
    end
  end
end
