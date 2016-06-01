
describe Document do
  context "#type?" do
    subject { document.type?(:nod) }

    context "when primary type matches" do
      let(:document) { Document.new(type: :nod) }
      it { is_expected.to be_truthy }
    end

    context "when an alt type matches" do
      let(:document) { Document.new(type: :form9, alt_types: [:soc, :nod]) }
      it { is_expected.to be_truthy }
    end

    context "when no types match" do
      let(:document) { Document.new(type: :form9, alt_types: [:soc]) }
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

      it { is_expected.to have_attributes(type: :form9, received_at: "TEST", alt_types: [:nod, :soc]) }
    end

    context "when doesn't have alt doc types" do
      let(:vbms_document) do
        OpenStruct.new(doc_type: "179", received_at: "TEST", alt_doc_types: nil)
      end

      it { is_expected.to have_attributes(type: :form9, received_at: "TEST") }
    end
  end
end
