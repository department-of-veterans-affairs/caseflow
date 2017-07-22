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
            received_at: expected_received_at1
          },
          {
            id: "2",
            type_id: "73",
            vbms_document_id: expected_document2.vbms_document_id,
            received_at: expected_received_at2
          }] }
      end

      let(:expected_received_at1) { Faker::Date.backward }
      let(:expected_received_at2) { Faker::Date.backward }
      let(:expected_response) { HTTPI::Response.new(200, [], expected_response_map.to_json) }
      let(:expected_document1) { Generators::Document.build(type: "SSOC", filename: nil) }
      let(:expected_document2) { Generators::Document.build(type: "NOD", filename: nil) }

      it "returns an array with all Document objects" do
        # Convert the received_at to a string so we can compare the results properly
        expected_document1.received_at = expected_received_at1.to_s
        expected_document2.received_at = expected_received_at2.to_s

        # Use to_hash to do a deep comparison and ensure all properties were deserialized correctly
        result = ExternalApi::EfolderService.fetch_documents_for(appeal).map(&:to_hash)
        expect(result).to contain_exactly(expected_document1.to_hash, expected_document2.to_hash)
      end
    end
  end
end
