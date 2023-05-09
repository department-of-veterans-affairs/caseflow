# frozen_string_literal: true

describe ExternalApi::PacmanService do
  let(:client_secret) { "SOME-FAKE-KEY" }
  let(:service_id) { "SOME-FAKE-SERVICE" }
  let(:error_response_body) { { "result": "error", "message": { "token": ["error"] } }.to_json }
  let(:error_response) do
    HTTPI::Response.new(400, {}, error_response_body)
  end
  let(:forbidden_response) do
    HTTPI::Response.new(403, {}, error_response_body)
  end
  let(:not_found_response) do
    HTTPI::Response.new(404, {}, error_response_body)
  end

  let(:distribution) do
    {
      "id": "123232323",
      "recipient": {
        "type": "person",
        "name": "bob joe",
        "firstName": "bob",
        "middleName": "",
        "lastName": "joe",
        "participant_id": "123455667",
        "poaCode": "",
        "claimantStationOfJurisdiction": ""
      },
      "description": "bad",
      "communicationPackageId": "",
      "destinations": {
        "type": "email",
        "addressLine1": "",
        "addressLine2": "",
        "addressLine3": "",
        "addressLine4": "",
        "addressLine5": "",
        "addressLine6": "",
        "treatLine2AsAddressee": 0,
        "treatLine3AsAddressee": 0,
        "city": "",
        "state": "",
        "postalCode": "",
        "countryName": "",
        "emailAddress": "",
        "phoneNumber": ""
      },
      "status": "",
      "sentToCbcmDate": ""
    }.to_json
  end

  let(:distribution_post_request) do
    {
      "communicationPackageId": "673c8b4a-cb7d-4fdf-bc4d-998d6d5d7431",
      "recipient": {
        "type": "system",
        "name": "VBMS-C"
      },
      "destinations": {
        "type": "domesticAddress",
        "addressLine1": "123 Test St.",
        "addressLine2": "",
        "addressLine3": "",
        "addressLine4": "",
        "addressLine5": "",
        "addressLine6": "",
        "city": "Anytown",
        "postalCode": "12345",
        "state": "DC",
        "countryName": "United States of America",
        "countryCode": "01"
      }
    }.to_json
  end

  let(:distribution_post_response) do
    {
      "id": "673c8b4a-cb7d-4fdf-bc4d-998d6d5d7431",
      "recipient": {
        "type": "system",
        "id": "2c6592fc-b3af-48ff-8263-c581c2f0a68b",
        "name": "VBMS-C"
      },
      "description": "Staging Distribution",
      "communicationPackageId": "673c8b4a-cb7d-4fdf-bc4d-998d6d5d7431",
      "destinations": {
        "type": "physicalAddress",
        "id": "5378bfbd-eff5-470c-bbc4-c7fd3c863a50",
        "status": null,
        "cbcmSendAttemptDate": "2022-06-06T16:35:28.017",
        "addressLine1": "POSTMASTER GENERAL",
        "addressLine2": "UNITED STATES POSTAL SERVICE",
        "addressLine3": "475 LENFANT PLZ SW RM 10022",
        "addressLine4": "SUITE 123",
        "addressLine5": "APO AE 09001-5275",
        "addressLine6": "",
        "treatLine2AsAddressee": false,
        "treatLine3AsAddressee": false,
        "city": "WASHINGTON DC",
        "state": "DC",
        "postalCode": "12345",
        "countryName": "UNITED STATES",
        "countryCode": "us"
      },
      "status": null,
      "sentToCbcmDate": null
    }.to_json
  end

  let(:package_post_request) do
    {
      "fileNumber": "123456789",
      "name": "ABC abc 1234 !*+,-.:;=?",
      "documentReferences": {
        "id": "3aec91cc-a88d-4b9c-9183-84bed583bbcc",
        "copies": 1
      }
    }.to_json
  end

  let(:package_post_response) do
    {
      "id": "24eb6a66-3833-4de6-bea4-4b614e55d5ac",
      "fileNumber": "123456789",
      "documentReferences": {
        "id": "23233175-6a87-4cd4-b327-f20cf5ef1222",
        "copies": 1
      },
      "status": "NEW",
      "createDate": ""
    }.to_json
  end

  let(:get_distribution_success_response) do
    HTTPI::Response.new(200, {}, distribution)
  end

  let(:post_distribution_success_response) do
    HTTPI::Response.new(201, {}, distribution_post_response)
  end

  let(:post_package_success_response) do
    HTTPI::Response.new(201, {}, package_post_response)
  end

  context "get distribution" do
    subject { ExternalApi::PacmanService.get_distribution_request(distribution["id"]) }
    it "gets correct distribution" do
      subject
      allow(HTTPI).to receive(:get).and_return(get_distribution_success_response)
      expect(subject.body.to_json).to eq(get_distribution_success_response)
    end
    context "not found" do
      subject { ExternalApi::PacmanService.get_distribution_request("fake") }
      it "returns 404 PacmanNotFoundError" do
        allow(HTTPI).to receive(:get).and_return(not_found_response)
        expect { subject }.to raise_error Caseflow::Error::PacmanNotFoundError
      end
    end
  end

  context "creates and submits distribution" do
    subject do
      ExternalApi::PacmanService.send_distribution_request(distribution_post_request["communicationPackageId"],
                                                           distribution_post_request["recipient"],
                                                           distribution_post_request["destinations"])
    end
    it "successfully sends distribution" do
      allow(HTTPI).to receive(:post).and_return(post_distribution_success_response)
      expect(subject.body.to_json).to eq(post_distribution_success_response)
    end
    context "not found" do
      it "returns 404 PacmanNotFoundError" do

      end
    end
  end

  context "creates and sends communication package" do
    subject do
      ExternalApi::PacmanService.send_communication_package_request(package_post_request["file_number"],
                                                                    package_post_request["name"],
                                                                    package_post_request["document_references"])
    end
    it "successfully sends package" do
      allow(HTTPI).to receive(:post).and_return(post_package_success_response)
      expect(subject.body.to_json).to eq(post_package_success_response)
    end
  end

  describe "response failure" do
    subject { ExternalApi::PacmanService.get_distribution_request(distribution["id"]) }

    context "400" do
      it "throws Caseflow::Error::PacmanBadRequestError" do
        allow(HTTPI).to receive(:get).and_return(error_response)
        expect { subject }.to raise_error Caseflow::Error::PacmanBadRequestError
      end
    end

    context "403" do
      it "throws Caseflow::Error::PacmanForbiddenError" do
        allow(HTTPI).to receive(:get).and_return(forbidden_response)
        expect { subject }.to raise_error Caseflow::Error::PacmanForbiddenError
      end
    end
  end
end
