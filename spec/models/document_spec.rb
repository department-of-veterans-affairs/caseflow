
describe Document do
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
          doc_type: "179",
          received_at: "TEST",
          alt_doc_types: ["Appeals - Notice of Disagreement (NOD)", "Appeals - Statement of the Case (SOC)"]
        )
      end

      it { is_expected.to have_attributes(type: "Form 9", received_at: "TEST", alt_types: %w(NOD SOC)) }
    end

    context "when doesn't have alt doc types" do
      let(:vbms_document) do
        OpenStruct.new(doc_type: "179", received_at: "TEST", alt_doc_types: nil)
      end

      it { is_expected.to have_attributes(type: "Form 9", received_at: "TEST") }
    end
  end

  context "#content" do
    let(:document) { Document.new(type: "NOD") }

    it "lazy loads document content" do
      expect(Fakes::AppealRepository).to receive(:fetch_document_file)

      document.content
    end

    context "doesn't load document content if it's already loaded" do
      before { document.content }

      it do
        expect(Fakes::AppealRepository).not_to receive(:fetch_document_file)
        document.content
      end
    end
  end

  context "#save!" do
    let(:document) { Document.new(type: "NOD") }
    let(:file) { document.default_path }

    before do
      if File.exist?(file)
        File.delete(file)
      end
    end

    it "writes document" do
      expect(File.exist?(file)).to be_falsey
      document.save!
      expect(File.exist?(file)).to be_truthy
    end
  end

  context "#default_path" do
    let(:document) { Document.new(type: "NOD", document_id: "123") }

    it "returns correct path" do
      expect(document.default_path).to match(/.*nod-123.pdf/)
    end
  end

end
