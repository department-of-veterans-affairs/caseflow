class Fakes::EfolderService
  class << self
    attr_accessor :document_records
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.fetch_document_file(document)
    # Mocks a call to <efolder>/documents/<vbms_doc_id>
    path =
      case document.vbms_document_id.to_i
      when 1
        File.join(Rails.root, "lib", "pdfs", "VA8.pdf")
      when 2
        File.join(Rails.root, "lib", "pdfs", "Formal_Form9.pdf")
      when 3
        File.join(Rails.root, "lib", "pdfs", "Informal_Form9.pdf")
      when 4
        File.join(Rails.root, "lib", "pdfs", "FakeDecisionDocument.pdf")
      when 5
        File.join(Rails.root, "lib", "pdfs", "megadoc.pdf")
      else
        file = File.join(Rails.root, "lib", "pdfs", "redacted", "#{document.vbms_document_id}.pdf")
        file = File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf") unless File.exist?(file)
        file
      end
    IO.binread(path)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.fetch_documents_for(appeal)
    (document_records || {})[appeal.vbms_id] || []
  end
end
