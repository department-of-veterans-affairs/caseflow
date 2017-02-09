require "rails_helper"

describe Document do
  let(:document) { Document.new(type: "NOD", vbms_document_id: "123") }
  let(:file) { document.default_path }

  context "#type?" do
    subject { document.type?("NOD") }

    context "when primary type matches" do
      let(:document) { Document.new(type: "NOD") }
      it { is_expected.to be_truthy }
    end

    context "when an alt type matches" do
      let(:document) { Document.new(type: "Form 9", alt_types: %w(SOC NOD)) }
      it { is_expected.to be_truthy }
    end

    context "when no types match" do
      let(:document) { Document.new(type: "Form 9", alt_types: ["SOC"]) }
      it { is_expected.to be_falsy }
    end
  end

  context ".from_vbms_document" do
    subject { Document.from_vbms_document(vbms_document) }

    context "when has alt doc types" do
      let(:vbms_document) do
        OpenStruct.new(
          vbms_document_id: "1"
          doc_type: "179",
          received_at: "TEST",
          alt_doc_types: ["Appeals - Notice of Disagreement (NOD)", "Appeals - Statement of the Case (SOC)"]
        )
      end

      it { is_expected.to have_attributes(type: "Form 9", received_at: "TEST", alt_types: %w(NOD SOC)) }
    end

    context "when doesn't have alt doc types" do
      let(:vbms_document) do
        OpenStruct.new(
          vbms_document_id: "1",
          doc_type: "179",
          received_at: "TEST",
          alt_doc_types: nil
        )
      end

      it { is_expected.to have_attributes(type: "Form 9", received_at: "TEST") }
    end
  end

  context "content tests" do
    context "#fetch_and_cache_document_from_vbms" do
      it "loads document content" do
        expect(Fakes::AppealRepository).to receive(:fetch_document_file).and_return("content!")
        expect(document.fetch_and_cache_document_from_vbms).to eq("content!")
      end
    end

    context "#fetch_content" do
      before do
        S3Service.files = {}
      end

      it "lazy fetches document content" do
        expect(Fakes::AppealRepository).to receive(:fetch_document_file).exactly(1).times.and_return("content!")
        document.fetch_content
        expect(document.fetch_content).to eq("content!")
      end
    end

    context "#content" do
      before do
        S3Service.files = {}
      end

      it "lazy loads document content" do
        expect(Fakes::AppealRepository).to receive(:fetch_document_file).exactly(1).times.and_return("content!")
        document.content
        expect(document.content).to eq("content!")
      end
    end
  end

  context "#serve!" do
    before do
      File.delete(file) if File.exist?(file)
      S3Service.files = {}
    end

    it "writes content to document" do
      expect(File.exist?(document.serve)).to be_truthy
    end
  end

  context "#file_name" do
    it "returns correct path" do
      expect(document.file_name).to match(/123/)
    end
  end

  context "#default_path" do
    it "returns correct path" do
      expect(document.default_path).to match(%r{.*\/tmp\/pdfs\/.*123})
    end
  end
end
