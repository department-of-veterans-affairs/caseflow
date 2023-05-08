# frozen_string_literal: true

describe ExternalApi::PacManService do
  let(:client_secret) { "SOME-FAKE-KEY" }
  let(:service_id) { "SOME-FAKE-SERVICE" }
  let(:error_response_body) { { "result": "error", "message": { "token": ["error"] } }.to_json }
  let(:participant_id) { "+1234567890" }
  let(:phone_number) { "+19876543210" }
  let(:status) { "in-progress" }
  let(:first_name) { "Bob" }
  let(:docket_number) { "1234567" }
  let(:success_response) do
    HTTPI::Response.new(200, {}, notification_response_body)
  end
  let(:sms_success_response) do
    HTTPI::Response.new(200, {}, sms_notification_response_body)
  end
  let(:status_success_response) do
    HTTPI::Response.new(200, {}, status_response_body)
  end
  let(:error_response) do
    HTTPI::Response.new(400, {}, error_response_body)
  end
  let(:forbidden_response) do
    HTTPI::Response.new(403, {}, error_response_body)
  end
  let(:not_found_response) do
    HTTPI::Response.new(404, {}, error_response_body)
  end

  context "get distribution" do
    it "gets correct distribution" do
    end
    context "bad request" do
      it "returns 400 PacManBadRequestError" do

      end
    end
    context "forbidden" do
      it "returns 403 PacManForbiddenError" do

      end
    end
    context "not found" do
      it "returns 404 PacManNotFoundError" do

      end
    end
  end

  context "creates and submits distribution" do
    it "successfully sends distribution" do
    end
    context "bad request" do
      it "returns 400 PacManBadRequestError" do

      end
    end
    context "forbidden" do
      it "returns 403 PacManForbiddenError" do

      end
    end
    context "not found" do
      it "returns 404 PacManNotFoundError" do

      end
    end
  end

  context "creates and sends communication package" do
    it "successfully sends package" do
    end
    context "bad request" do
      it "returns 400 PacManBadRequestError" do

      end
    end
    context "forbidden" do
      it "returns 403 PacManForbiddenError" do

      end
    end
  end

  describe "response failure" do
    let!(:error_code) { nil }

    before(:each) do
      allow(VADotGovService).to receive(:send_va_dot_gov_request)
        .and_return(HTTPI::Response.new(error_code, {}, {}.to_json))
    end

    context "429" do
      let!(:error_code) { 400 }

      it "throws Caseflow::Error::VaDotGovLimitError" do
        expect(VADotGovService.get_facility_data(ids: ["vba_372"]).error)
          .to be_an_instance_of(Caseflow::Error::VaDotGovLimitError)
      end
    end

    context "400" do
      let!(:error_code) { 403 }

      it "throws Caseflow::Error::VaDotGovRequestError" do
        expect(VADotGovService.get_facility_data(ids: ["vba_372"]).error)
          .to be_an_instance_of(Caseflow::Error::VaDotGovRequestError)
      end
    end

    context "500" do
      let!(:error_code) { 404 }

      it "throws Caseflow::Error::VaDotGovServerError" do
        expect(VADotGovService.get_facility_data(ids: ["vba_372"]).error)
          .to be_an_instance_of(Caseflow::Error::VaDotGovServerError)
      end
    end
  end
end
