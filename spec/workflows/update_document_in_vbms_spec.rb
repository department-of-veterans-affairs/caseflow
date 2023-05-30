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

  describe "#pdf_location" do
    it "fetches file from s3 and returns temporary location" do
      pdf_name = "veteran-#{document.veteran_file_number}-doc-#{document.id}.pdf"
      expect(Caseflow::Fakes::S3Service).to receive(:fetch_file)
      expect(doc_to_upload.pdf_location)
        .to eq File.join(Rails.root, "tmp", "pdfs", pdf_name)
    end
  end

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

  describe "#s3_location" do
    context "fetches a bucket name based on document type" do
      it "changes based on specific document types" do
        document.document_type = "BVA Case Notifications"
        expect(doc_to_upload.send(:s3_location)).to include("notification-reports")
      end
      it "defaults to idt-uploaded-documents" do
        expect(doc_to_upload.send(:s3_location)).to include("idt-uploaded-documents")
      end
    end
  end

  context "#call" do
    subject { doc_to_upload.call }

    before do
      allow(VBMSService).to receive(:update_document_in_vbms).and_call_original
    end

    context "the document has already been uploaded" do
      let(:uploaded_to_vbms_at) { Time.zone.now }

      it "does not reupload the document" do
        subject
        expect(VBMSService).to_not have_received(:update_document_in_vbms)
      end
    end

    context "there was no upload error" do
      it "uploads document" do
        subject

        expect(VBMSService).to have_received(:update_document_in_vbms).with(
          document.appeal, doc_to_upload
        )
        expect(document.uploaded_to_vbms_at).to eq(Time.zone.now)
        expect(document.processed_at).to_not be_nil
        expect(document.submitted_at).to eq(Time.zone.now)
      end
    end

    context "when there was an upload error" do
      before do
        allow(VBMSService).to receive(:update_document_in_vbms).and_raise("Some VBMS error")
      end

      it "saves document as attempted but not processed and saves the error" do
        expect { subject }.to raise_error("Some VBMS error")

        expect(document.attempted_at).to eq(Time.zone.now)
        expect(document.processed_at).to be_nil
        expect(document.error).to eq("Some VBMS error")
      end
    end

    context "the document has already been processed" do
      let(:processed_at) { Time.zone.now }

      it "does not do anything" do
        expect(S3Service).to_not receive(:store_file)

        subject

        expect(VBMSService).to_not have_received(:update_document_in_vbms)
        expect(document.submitted_at).to be_nil
        expect(document.processed_at).to_not be_nil
      end
    end
  end

  context "#cache_file" do
    it "stores the file in S3" do
      expected_path = "idt-uploaded-documents/veteran-#{document.veteran_file_number}-doc-#{document.id}.pdf"

      expect(S3Service).to receive(:store_file).with(expected_path, /PDF/)

      doc_to_upload.cache_file
    end
  end
end
