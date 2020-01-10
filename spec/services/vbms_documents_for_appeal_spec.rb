# frozen_string_literal: true

require "support/fake_vbms_client"
require "support/fake_bgs_client"

describe ExternalApi::VbmsDocumentsForAppeal do
  let(:veteran_file_number) { "12345678" }
  let(:nonexistent_file_number_error) do
    VBMS::FilenumberDoesNotExist.new(500, "File Number does not exist within the system.")
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
      expect { docs.fetch }.to raise_error(VBMS::FilenumberDoesNotExist)
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
      expect { docs.fetch }.to raise_error(VBMS::FilenumberDoesNotExist)
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
      expect { docs.fetch }.to raise_error(VBMS::FilenumberDoesNotExist)
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

  context "vbms_pagination feature toggle is on, pagination service is used" do
    before do
      FeatureToggle.enable!(:vbms_pagination)
    end

    after do
      FeatureToggle.disable!(:vbms_pagination)
    end

    let(:pagination_service) { VBMS::Service::PagedDocuments.new(client: vbms_client) }
    let(:vbms_client) { FakeVbmsClient.new }
    let(:bgs_client) { FakeBgsClient.new }
    let(:docs) do
      ExternalApi::VbmsDocumentsForAppeal.new(
        file_number: veteran_file_number, vbms_client: vbms_client, bgs_client: bgs_client
      )
    end

    context "when file number exists in VBMS" do
      it "returns documents" do
        docs_from_vbms_response = [1, 2, 3]
        docs_from_vbms_docs = [4, 5, 6]

        # mock the pagination service
        allow(docs).to receive(:vbms_paged_documents_service) { pagination_service }
        allow(pagination_service).to receive(:call).and_return(documents: docs_from_vbms_response)

        # mock the internal DocumentsFromVbmsDocuments object
        docs_from_vbms = instance_double(DocumentsFromVbmsDocuments)
        allow(DocumentsFromVbmsDocuments).to receive(:new).with(
          documents: docs_from_vbms_response, file_number: veteran_file_number
        ).and_return(docs_from_vbms)
        allow(docs_from_vbms).to receive(:call).and_return(docs_from_vbms_docs)

        result_hash = {
          manifest_vbms_fetched_at: nil,
          manifest_vva_fetched_at: nil,
          documents: docs_from_vbms_docs
        }

        # validate that the older non-pagination service is not used
        expect(bgs_client).to_not receive(:fetch_veteran_info)
        expect(vbms_client).to_not receive(:send_request)

        # exercise the mocked objects
        expect(docs.fetch).to eq result_hash
      end
    end

    context "when VBMS cannot find file number and BGS claim number is different from file number" do
      it "looks up the BGS claim number in VBMS" do
        bgs_claim_number = "87654321"

        # mock service to fail for both numbers
        allow(pagination_service).to receive(:call)
          .with(file_number: veteran_file_number).and_raise(nonexistent_file_number_error)
        allow(pagination_service).to receive(:call)
          .with(file_number: bgs_claim_number).and_raise(nonexistent_file_number_error)

        # mock bgs service to return claim number
        allow(bgs_client).to receive(:fetch_veteran_info).with(veteran_file_number)
          .and_return(claim_number: bgs_claim_number)

        # inject our mocked pagination service
        allow(docs).to receive(:vbms_paged_documents_service) { pagination_service }

        # confirm everything gets called as expected
        expect(pagination_service).to receive(:call).with(file_number: veteran_file_number).once
        expect(pagination_service).to receive(:call).with(file_number: bgs_claim_number).once
        expect(bgs_client).to receive(:fetch_veteran_info).once
        expect { docs.fetch }.to raise_error(VBMS::FilenumberDoesNotExist) # the 2nd, BGS attempt.
      end
    end
  end
end
