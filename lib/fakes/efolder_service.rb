class Fakes::EfolderService
  class << self
    attr_accessor :document_records
  end

  @test_pdf_directory = Pathname.new(File.join(Rails.root, "lib", "pdfs"))

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.fetch_document_file(document)
    # Mocks a call to <efolder>/documents/<vbms_doc_id>
    path =
      case document.vbms_document_id.to_i
      when 1
        @test_pdf_directory.join("VA8.pdf")
      when 2
        @test_pdf_directory.join("Formal_Form9.pdf")
      when 3
        @test_pdf_directory.join("Informal_Form9.pdf")
      when 4
        @test_pdf_directory.join("FakeDecisionDocument.pdf")
      when 5
        @test_pdf_directory.join("megadoc.pdf")
      else
        file = @test_pdf_directory.join("redacted", "#{document.vbms_document_id}.pdf")
        file = @test_pdf_directory.join("KnockKnockJokes.pdf") unless File.exist?(file)
        file
      end
    IO.binread(path)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.fetch_documents_for(appeal)
    (document_records || {})[appeal.vbms_id] || []
  end
end
