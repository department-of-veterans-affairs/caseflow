# frozen_string_literal: true

describe ExternalApi::GovDeliveryService do
  let(:gov_delivery_url) { "fake.tms.govdelivery.com" }
  let(:auth_token) { "SOME-FAKE-TOKEN" }
  let(:cert_file_location) { "/path/to/cert/file" }

  before do
    stub_const("ENV", "GOVDELIVERY_SERVER" => gov_delivery_url)
    stub_const("ENV", "GOVDELIVERY_TOKEN" => auth_token)
    stub_const("ENV", "SSL_CERT_FILE" => cert_file_location)
  end

  let(:gov_delivery_service) { ExternalApi::GovDeliveryService.new }
  let(:email_endpoint) { "/messages/email" }
  let(:webhook_endpoint) { "/webhooks" }
  let(:webhook_id) { "456" }

  shared_examples "error responses" do
    describe "response failure" do
      let!(:error_code) { nil }

      before(:each) do
        allow(gov_delivery_service).to receive(:send_gov_delivery_request)
          .and_return(HTTPI::Response.new(error_code, {}, {}.to_json))
      end

      context "fallback error code" do
        it "throws Caseflow::Error::GovDeliveryApiError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryApiError)
        end
      end

      context "401" do
        let!(:error_code) { 401 }

        it "throws Caseflow::Error::GovDeliveryUnauthorizedError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryUnauthorizedError)
        end
      end

      context "403" do
        let!(:error_code) { 403 }

        it "throws Caseflow::Error::GovDeliveryForbiddenError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryForbiddenError)
        end
      end

      context "404" do
        let!(:error_code) { 404 }

        it "throws Caseflow::Error::GovDeliveryNotFoundError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryNotFoundError)
        end
      end

      context "500" do
        let!(:error_code) { 500 }

        it "throws Caseflow::Error::GovDeliveryInternalServerError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryInternalServerError)
        end
      end

      context "502" do
        let!(:error_code) { 502 }

        it "throws Caseflow::Error::GovDeliveryBadGatewayError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryBadGatewayError)
        end
      end

      context "503" do
        let!(:error_code) { 503 }

        it "throws Caseflow::Error::GovDeliveryServiceUnavailableError" do
          expect(subject.error).to be_an_instance_of(Caseflow::Error::GovDeliveryServiceUnavailableError)
        end
      end
    end
  end

  describe "#create_webhook" do
    let(:external_message_id) { "1234" }
    let(:body) do
      {
        "url": "",
        "event_type": "sent"
      }
    end

    subject { gov_delivery_service.create_webhook(external_message_id: external_message_id, event_type: "sent") }

    let(:success_create_resp) do
      HTTPI::Response.new(200, {}, { "_links" => { "self" => webhook_id } }.to_json)
    end

    it "calls #send_gov_delivery_request" do
      expect(gov_delivery_service).to receive(:send_gov_delivery_request)
      subject
    end

    it "passed correct arguments to #send_gov_delivery_request" do
      expect(gov_delivery_service).to receive(:send_gov_delivery_request).with(webhook_endpoint, :post, body: body)
      subject
    end

    it "returns an instance of ExternalApi::GovDeliveryService::CreateResponse class" do
      allow(gov_delivery_service).to receive(:send_gov_delivery_request).with(webhook_endpoint, :post, body: body)
        .and_return(success_create_resp)

      expect(subject).to be_instance_of(ExternalApi::GovDeliveryService::CreateResponse)
    end

    it "success response" do
      allow(gov_delivery_service).to receive(:send_gov_delivery_request).with(webhook_endpoint, :post, body: body)
        .and_return(success_create_resp)

      expect(subject.code).to eq(200)
      expect(subject.success?).to eq(true)
      expect(subject.body.dig("_links", "self")).to eq(webhook_id)
    end

    include_examples "error responses"
  end

  describe "#delete_webhook" do
    subject { gov_delivery_service.delete_webhook(webhook_id: webhook_id) }

    let(:success_del_resp) { HTTPI::Response.new(200, {}, {}) }

    it "calls #send_gov_delivery_request" do
      expect(gov_delivery_service).to receive(:send_gov_delivery_request)
      subject
    end

    it "passed correct arguments to #send_gov_delivery_request" do
      expect(gov_delivery_service).to receive(:send_gov_delivery_request)
        .with("#{webhook_endpoint}/#{webhook_id}", :delete)
      subject
    end

    it "success response" do
      allow(gov_delivery_service).to receive(:send_gov_delivery_request)
        .with("#{webhook_endpoint}/#{webhook_id}", :delete)
        .and_return(success_del_resp)

      expect(subject.code).to eq(200)
      expect(subject.success?).to eq(true)
      expect(subject.data).to eq(nil)
    end

    include_examples "error responses"
  end

  describe "#list_all_webhooks" do
    let(:webhooks_list) { [["failed", "/webhooks/12345"], ["inconclusive", "/webhooks/23456"]] }

    subject { gov_delivery_service.list_all_webhooks }

    let(:success_create_resp) do
      HTTPI::Response.new(200, {}, { "_links" => { "self" => webhooks_list } }.to_json)
    end

    it "calls #send_gov_delivery_request" do
      expect(gov_delivery_service).to receive(:send_gov_delivery_request)
      subject
    end

    it "passed correct arguments to #send_gov_delivery_request" do
      expect(gov_delivery_service).to receive(:send_gov_delivery_request).with(webhook_endpoint, :get)
      subject
    end

    it "returns an instance of ExternalApi::GovDeliveryService::CreateResponse class" do
      allow(gov_delivery_service).to receive(:send_gov_delivery_request).with(webhook_endpoint, :get)
        .and_return(success_create_resp)

      expect(subject).to be_instance_of(ExternalApi::GovDeliveryService::Response)
    end

    it "success response" do
      allow(gov_delivery_service).to receive(:send_gov_delivery_request).with(webhook_endpoint, :get)
        .and_return(success_create_resp)

      expect(subject.code).to eq(200)
      expect(subject.success?).to eq(true)
      expect(subject.body.dig("_links", "self")).to eq(webhooks_list)
    end

    include_examples "error responses"
  end
end
