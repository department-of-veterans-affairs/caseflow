# frozen_string_literal: true

describe ExternalApi::VANotifyService do
  let(:notification_url) { "fake.api.vanotify.com" }
  let(:client_secret) { "SOME-FAKE-KEY" }
  let(:service_id) { "SOME-FAKE-SERVICE" }
  let(:template_id) { "3fa85f64-5717-4562-b3fc-2c963f66afa6" }
  let(:email_address) { "test@va.gov" }
  let(:response_body) { { {"template": "id" } => template_id }.to_json }
  let(:phone_number) { "+19876543210" }
  let(:success_response) do
    HTTPI::Response.new(200, {}, response_body)
  end

  before do
    stub_const("ENV", "notification-url" => notification_url)
    stub_const("ENV", "service-api-key" => client_secret)
    stub_const("ENV", "service-id" => service_id)
  end

  context "notifications sent" do
    describe "emails sent" do
      subject { ExternalApi::VANotifyService.send_notifications(email_address, template_id) }
      it "email sent successfully" do
        allow(HTTPI).to receive(:post).and_return(success_response)
        expect(success_response.body).to eq(response_body)
      end
    end

    describe "sms sent" do
      subject { ExternalApi::VANotifyService.send_notifications(email_address, email_template_id, phone_number, template_id) }
      it "email and sms sent successfully" do
        allow(HTTPI).to receive(:post).and_return(success_response)
        expect(success_response.body).to eq(response_body)
      end
    end
  end

  context "response failure" do
    let!(:error_code) { nil }
    before do
      allow(ExternalApi::VANotifyService).to receive(:send_va_notify_request)
        .and_return(HTTPI::Response.new(error_code, {}, {}.to_json))
    end

    context "fallback error code" do
      it "throws Caseflow::Error::VANotifyApiError" do
        expect { subject }.to raise_error Caseflow::Error::VANotifyApiError
      end
    end

    context "401" do
      let!(:error_code) { 401 }
      it "throws Caseflow::Error::VANotifyUnauthorizedError" do
        expect { subject }.to raise_error Caseflow::Error::VANotifyUnauthorizedError
      end
    end

    context "403" do
      let!(:error_code) { 403 }

      it "throws Caseflow::Error::VANotifyForbiddenError" do
        expect { subject }.to raise_error Caseflow::Error::VANotifyForbiddenError
      end
    end

    context "404" do
      let!(:error_code) { 404 }

      it "throws Caseflow::Error::VANotifyNotFoundError" do
        expect { subject }.to raise_error Caseflow::Error::VANotifyNotFoundError
      end
    end

    context "429" do
      let!(:error_code) { 429 }
      it "throws Caseflow::Error::Error::VANotifyRateLimitError" do
        expect { subject }.to raise_error Caseflow::Error::VANotifyRateLimitError
      end
    end

    context "500" do
      let!(:error_code) { 500 }

      it "throws Caseflow::Error::VANotifyInternalServerError" do
        expect { subject }.to raise_error Caseflow::Error::VANotifyInternalServerError
      end
    end
  end
end
