# frozen_string_literal: true

require "support/fake_vbms_client"
require "support/fake_bgs_client"

describe ExternalApi::VbmsDocumentsForAppeal do
  let(:veteran_file_number) { "12345678" }
  let(:nonexistent_file_number_error) do
    VBMS::ClientError.new(message: "File Number does not exist within the system.")
  end

  context "when VBMS cannot find file number and BGS returns nil for claim number" do
    it "raises and does not try to look up the nil number in VBMS" do
      vbms_client = FakeVbmsClient.new
      bgs_client = FakeBgsClient.new
      docs = ExternalApi::VbmsDocumentsForAppeal.new(
        file_number: veteran_file_number, vbms_client: vbms_client, bgs_client: bgs_client
      )

      allow(vbms_client).to receive(:send_request).and_raise(nonexistent_file_number_error)
      allow(bgs_client).to receive(:fetch_veteran_info).with(veteran_file_number)
        .and_return({})

      expect(vbms_client).to receive(:send_request).exactly(:once)
      expect { docs.fetch }.to raise_error(VBMSError::FilenumberDoesNotExist)
    end
  end

  context "when VBMS cannot find file number and BGS claim number is same as file number" do
    it "raises and does not try to look up the same number in VBMS" do
      vbms_client = FakeVbmsClient.new
      bgs_client = FakeBgsClient.new
      docs = ExternalApi::VbmsDocumentsForAppeal.new(
        file_number: veteran_file_number, vbms_client: vbms_client, bgs_client: bgs_client
      )

      allow(vbms_client).to receive(:send_request).and_raise(nonexistent_file_number_error)
      allow(bgs_client).to receive(:fetch_veteran_info).with(veteran_file_number)
        .and_return(claim_number: veteran_file_number)

      expect(vbms_client).to receive(:send_request).exactly(:once)
      expect { docs.fetch }.to raise_error(VBMSError::FilenumberDoesNotExist)
    end
  end

  context "when VBMS cannot find file number and BGS claim number is different from file number" do
    it "looks up the BGS claim number in VBMS" do
      vbms_client = FakeVbmsClient.new
      bgs_client = FakeBgsClient.new
      docs = ExternalApi::VbmsDocumentsForAppeal.new(
        file_number: veteran_file_number, vbms_client: vbms_client, bgs_client: bgs_client
      )
      bgs_claim_number = "87654321"

      allow(vbms_client).to receive(:send_request).and_raise(nonexistent_file_number_error)
      allow(bgs_client).to receive(:fetch_veteran_info).with(veteran_file_number)
        .and_return(claim_number: bgs_claim_number)

      expect(vbms_client).to receive(:send_request).exactly(:twice)
      expect(VBMS::Requests::FindDocumentVersionReference)
        .to receive(:new).with(veteran_file_number)
      expect(VBMS::Requests::FindDocumentVersionReference).to receive(:new).with(bgs_claim_number)
      expect { docs.fetch }.to raise_error(VBMSError::FilenumberDoesNotExist)
    end
  end

  context "when file number exists in VBMS" do
    it "returns documents" do
      vbms_client = FakeVbmsClient.new
      bgs_client = FakeBgsClient.new
      docs = ExternalApi::VbmsDocumentsForAppeal.new(
        file_number: veteran_file_number, vbms_client: vbms_client, bgs_client: bgs_client
      )
      docs_from_vbms_array = [4, 5, 6]
      docs_from_vbms = instance_double(DocumentsFromVbmsDocuments)
      allow(DocumentsFromVbmsDocuments).to receive(:new).and_return(docs_from_vbms)
      allow(docs_from_vbms).to receive(:call).and_return(docs_from_vbms_array)

      allow(vbms_client).to receive(:send_request).and_return([1, 2, 3])
      result_hash = {
        manifest_vbms_fetched_at: nil,
        manifest_vva_fetched_at: nil,
        documents: docs_from_vbms_array
      }

      expect(bgs_client).to_not receive(:fetch_veteran_info)
      expect(vbms_client).to receive(:send_request).exactly(:once)
      expect(VBMS::Requests::FindDocumentVersionReference)
        .to receive(:new).with(veteran_file_number)

      expect(docs.fetch).to eq result_hash
    end
  end
end
