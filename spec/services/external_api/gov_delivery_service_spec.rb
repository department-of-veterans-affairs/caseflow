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

  let(:hearing_date) { Time.zone.now }
  let(:hearing_day_request_type) { HearingDay::REQUEST_TYPES[:video] }
  let(:hearing_day_ro) { "RO01" }
  let(:hearing_day) do
    create(
      :hearing_day,
      request_type: hearing_day_request_type,
      regional_office: hearing_day_ro,
      scheduled_for: hearing_date
    )
  end
  let(:hearing) do
    create(
      :hearing,
      hearing_day: hearing_day,
      created_at: Time.zone.now - 14.days
    )
  end
  let!(:appellant_recipient) do
    create(
      :hearing_email_recipient,
      :appellant_hearing_email_recipient,
      hearing: hearing,
      timezone: "America/New_York"
    )
  end
  let(:email_event) do
    create(
      :sent_hearing_email_event,
      :reminder,
      recipient_role: HearingEmailRecipient::RECIPIENT_ROLES[:veteran],
      email_recipient: hearing.appellant_recipient
    )
  end
  let(:endpoint) { "#{email_event.external_message_id}/recipients" }

  describe "#get_message_status" do
    let(:event_status) { "sent" }

    subject { ExternalApi::GovDeliveryService.get_message_by_event(email_event: email_event) }

    let(:success_create_resp) do
      HTTPI::Response.new(200, {}, { "status" => event_status }.to_json)
    end

    it "calls #send_gov_delivery_request" do
      expect(ExternalApi::GovDeliveryService).to receive(:send_gov_delivery_request)
      subject
    end

    it "passed correct arguments to #send_gov_delivery_request" do
      expect(ExternalApi::GovDeliveryService).to receive(:send_gov_delivery_request).with(endpoint, :get)
      subject
    end

    it "returns an instance of ExternalApi::GovDeliveryService::CreateResponse class" do
      allow(ExternalApi::GovDeliveryService).to receive(:send_gov_delivery_request).with(endpoint, :get)
        .and_return(success_create_resp)

      expect(subject).to be_instance_of(ExternalApi::GovDeliveryService::Response)
    end

    it "success response" do
      allow(ExternalApi::GovDeliveryService).to receive(:send_gov_delivery_request).with(endpoint, :get)
        .and_return(success_create_resp)

      expect(subject.code).to eq(200)
      expect(subject.success?).to eq(true)
      expect(subject.body.dig("status")).to eq(event_status)
    end

    context "response failure" do
      let!(:error_code) { nil }

      before(:each) do
        allow(ExternalApi::GovDeliveryService).to receive(:send_gov_delivery_request)
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
end
