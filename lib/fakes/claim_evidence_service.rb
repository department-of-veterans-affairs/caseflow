# frozen_string_literal: true

class Fakes::ClaimEvidenceService
  class << self
    def get_ocr_document(doc_series_id)
      if doc_series_id.even?
        ocr_data = <<~OCR_DATA
          The quick brown fox jumps over the lazy dog.
        OCR_DATA
      else
        ocr_data = <<~OCR_DATA
          The five boxing wizards jump quickly.
        OCR_DATA
      end

      ocr_data
    end

    def document_types
    end
  end
end
