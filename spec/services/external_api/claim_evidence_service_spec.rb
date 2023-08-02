# frozen_string_literal: true

describe ExternalApi::ClaimEvidenceService do
  let(:notification_url) { "fake.api.vanotify.com" }
  let(:client_secret) { "SOME-FAKE-KEY" }
  let(:service_id) { "SOME-FAKE-SERVICE" }

  let(:doc_types_body) { { "documentTypes": [{
      "id": 150,
      "createDateTime": "2012-01-25",
      "modifiedDateTime": "2016-03-01T16:18:56",
      "name": "L141",
      "description": "VA 21-8056 Request for Retirement Information from the Railroad Retirement Board and Certification of Information From Department of Veterans Affairs",
      "isUserUploadable": true,
      "is526": false,
      "documentCategory": {
        "id": 70,
        "createDateTime": "2012-01-25",
        "modifiedDateTime": "2016-03-01T16:18:56",
        "description": "Correspondence",
        "subDescription": "Miscellaneous "
      }
    },
    {
      "id": 152,
      "createDateTime": "2012-01-25",
      "modifiedDateTime": "2016-03-01T16:18:56",
      "name": "L143",
      "description": "VA 21-8358 Notice to Department of Veterans Affairs of Admission to Uniformed Services Hospital",
      "isUserUploadable": true,
      "is526": false,
      "documentCategory": {
        "id": 70,
        "createDateTime": "2012-01-25",
        "modifiedDateTime": "2016-03-01T16:18:56",
        "description": "Correspondence",
        "subDescription": "Miscellaneous "
      }
    },]}.to_json }

  let(:alt_doc_types_body) {
    { "alternativeDocumentTypes": [
      {
        "id": 1,
        "createDateTime": "2016-04-13",
        "modifiedDateTime": "2016-04-13T04:00:00",
        "description": "Notice of Disagreement (NOD)",
        "categoryDescription": "Appeals",
        "name": "L1"
      },
      {
        "id": 2,
        "createDateTime": "2016-04-13",
        "modifiedDateTime": "2016-04-13T04:00:00",
        "description": "Substantive Appeal to Board of Veterans' Appeals",
        "categoryDescription": "Appeals",
        "name": "L2"
      },
      {
        "id": 3,
        "createDateTime": "2016-04-13",
        "modifiedDateTime": "2016-04-13T04:00:00",
        "description": "Statement of the Case (SOC)",
        "categoryDescription": "Appeals",
        "name": "L3"
      },
      {
        "id": 4,
        "createDateTime": "2016-04-13",
        "modifiedDateTime": "2016-04-13T04:00:00",
        "description": "Supplemental Statement of the Case (SSOC)",
        "categoryDescription": "Appeals",
        "name": "L4"
      }
    ]}.to_json
  }

  let(:error_response_body) { { "result": "error", "message": { "token": ["error"] } }.to_json }

  let(:success_doc_types_response) do
    HTTPI::Response.new(200, {}, doc_types_body)
  end

  let(:success_alt_doc_types_response) do
    HTTPI::Response.new(200, {}, alt_doc_types_body)
  end
  let(:error_response) do
    HTTPI::Response.new(400, {}, error_response_body)
  end
  let(:unauthorized_response) do
    HTTPI::Response.new(401, {}, error_response_body)
  end
  let(:forbidden_response) do
    HTTPI::Response.new(403, {}, error_response_body)
  end
  let(:not_found_response) do
    HTTPI::Response.new(404, {}, error_response_body)
  end
  let(:rate_limit_response) do
    HTTPI::Response.new(429, {}, error_response_body)
  end
  let(:internal_server_error_response) do
    HTTPI::Response.new(500, {}, error_response_body)
  end

  it "document types" do
    allow(HTTPI).to receive(:get).and_return(success_doc_types_response)
    document_types = ExternalApi::ClaimEvidenceService.document_types
    expect(document_types).to be_present
  end

  it "alt_document_types" do
    allow(HTTPI).to receive(:get).and_return(success_alt_doc_types_response)
    alt_document_types = ExternalApi::ClaimEvidenceService.alt_document_types
    expect(alt_document_types).to be_present
  end

  context "resonse failure" do
    subject { ExternalApi::ClaimEvidenceService.document_types }
    context "throws fallback error" do
      it "throws Caseflow::Error::ClaimEvidenceApiError" do
        allow(HTTPI).to receive(:get).and_return(error_response)
        expect { subject }.to raise_error Caseflow::Error::ClaimEvidenceApiError
      end
    end

    context "401" do
      it "throws Caseflow::Error::ClaimEvidenceUnauthorizedError" do
        allow(HTTPI).to receive(:get).and_return(unauthorized_response)
        expect { subject }.to raise_error Caseflow::Error::ClaimEvidenceUnauthorizedError
      end
    end

    context "403" do
      it "throws Caseflow::Error::ClaimEvidenceForbiddenError" do
        allow(HTTPI).to receive(:get).and_return(forbidden_response)
        expect { subject }.to raise_error Caseflow::Error::ClaimEvidenceForbiddenError
      end
    end

    context "404" do
      it "throws Caseflow::Error::ClaimEvidenceNotFoundError" do
        allow(HTTPI).to receive(:get).and_return(not_found_response)
        expect { subject }.to raise_error Caseflow::Error::ClaimEvidenceNotFoundError
      end
    end

    context "500" do
      let!(:error_code) { 500 }
      it "throws Caseflow::Error:ClaimEvidenceInternalServerError" do
        allow(HTTPI).to receive(:get).and_return(internal_server_error_response)
        expect { subject }.to raise_error Caseflow::Error::ClaimEvidenceInternalServerError
      end
    end
  end
end
