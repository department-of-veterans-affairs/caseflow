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
end