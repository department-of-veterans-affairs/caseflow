require "rails_helper"
require "Faker"

describe ExternalApi::EfolderService do
  let(:base_url) { Faker::Internet.url }

  context "#fetch_documents_for" do
    let(:appeal) { Generators::Appeal. build }
    subject { EFolderService.fetch_documents_for(appeal) }

    context "appeal with multiple documents" do
      before do
        expect(ExternalApi::EfolderService).to receive(:efolder_base_url).and_return(base_url).once
        expect(ExternalApi::EfolderService).to receive(:efolder_token).and_return(Faker::Internet.device_token).once
        expect(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(expected_response).once
      end

      let(:expected_response_map) do
        { data: [
          {
            id: "1",
            type_id: "97",
            vbms_document_id: expected_document1.vbms_document_id,
            received_at: expected_document1.received_at
          },
          {
            id: "2",
            type_id: "73",
            vbms_document_id: expected_document2.vbms_document_id,
            received_at: expected_document2.received_at
          }] }
      end

      let(:expected_response) { HTTPI::Response.new(200, [], expected_response_map.to_json) }
      let(:expected_document1) { Generators::Document.build(type: "SSOC", filename: nil) }
      let(:expected_document2) { Generators::Document.build(type: "NOD", filename: nil) }

      it "returns an array with all Document objects" do
        x = expected_response
        ans = ExternalApi::EfolderService.fetch_documents_for(appeal).map{|document| document.to_hash}
        expect(ans[0]).to eq(expected_document1.to_hash)
        expect(ans).to contain_exactly(expected_document1.to_hash, expected_document2.to_hash)
      end
    end
  end
end
