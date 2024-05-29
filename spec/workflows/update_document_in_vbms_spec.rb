# frozen_string_literal: true

describe UpdateDocumentInVbms, :postgres do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:veteran) { create(:veteran) }
  let(:appeal) do
    create(:appeal, number_of_claimants: 1, veteran_file_number: veteran.file_number)
  end
  let(:document) do
    create(
      :vbms_uploaded_document,
      uploaded_to_vbms_at: uploaded_to_vbms_at,
      veteran_file_number: appeal.veteran_file_number,
      processed_at: processed_at,
      file: "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW",
      document_version_reference_id: "prev_ref_id"
    )
  end
  let(:uploaded_to_vbms_at) { nil }
  let(:processed_at) { nil }
  let!(:doc_to_upload) { UpdateDocumentInVbms.new(document: document) }
  let(:transaction_method) { :update_document_in_vbms }
  let(:upload_arg) { document.appeal }

  include_examples "VBMS Document Storage Location Tests"

  describe "#source" do
    it "is hardcoded to BVA" do
      expect(doc_to_upload.source).to eq "BVA"
    end
  end

  describe "#document_type_id" do
    it "fetches the ID corresponding to the document type string" do
      expect(doc_to_upload.document_type_id).to eq 482
    end
  end

  describe "#document_type" do
    it "reads it from the document instance" do
      expect(doc_to_upload.document_type).to eq document.document_type
    end
  end
end
