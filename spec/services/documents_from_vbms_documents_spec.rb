# frozen_string_literal: true

describe DocumentsFromVbmsDocuments do
  it "calls Document.from_vbms_document" do
    documents_array = %w[foo bar]
    file_number = "12345678"

    allow(Document).to receive(:from_vbms_document)
      .with("foo", "12345678").and_return("foodoc")
    allow(Document).to receive(:from_vbms_document)
      .with("bar", "12345678").and_return("bardoc")

    result = DocumentsFromVbmsDocuments.new(
      documents: documents_array, file_number: file_number
    ).call

    expect(result).to match_array(%w[foodoc bardoc])
  end
end
