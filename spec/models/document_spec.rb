
describe Document do
  context ".from_vbms_document" do
    let(:vbms_document) do
      OpenStruct.new(doc_type: "179", received_at: "TEST")
    end
    subject { Document.from_vbms_document(vbms_document) }
    it { is_expected.to have_attributes(type: :form9, received_at: "TEST") }
  end
end
