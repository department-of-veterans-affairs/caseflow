# frozen_string_literal: true

describe ExternalApi::VANotifyService do
  let(:notification_url) { "fake.api.vanotify.com" }
  let(:client_secret) { "SOME-FAKE-KEY" }
  let(:service_id) { "SOME-FAKE-SERVICE" }
  let(:email_template_id) { "some-fake-email-template" }
  let(:sms_template_id) { "some-fake-sms-template" }
  let(:notification_id) { "some-fake-notification" }
  let(:email_address) { "test@va.gov" }
  let(:notification_response_body) { { "template": { "id" => email_template_id } }.to_json }
  let(:sms_notification_response_body) { { "template": { "id" => sms_template_id } }.to_json }
  let(:status_response_body) { { "status" => "delivered" }.to_json }
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

  context "notifications sent" do
    describe "email" do
      subject do
        ExternalApi::VANotifyService.send_email_notifications(
          participant_id, notification_id, email_template_id, first_name, docket_number, status
        )
      end
      it "email sent successfully" do
        allow(HTTPI).to receive(:post).and_return(success_response)
        expect(subject.body["template"]["id"]).to eq(email_template_id)
      end

      context "429" do
        it "throws Caseflow::Error::VANotifyRateLimitError" do
          allow(HTTPI).to receive(:post).and_return(rate_limit_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyRateLimitError
        end
      end
    end

    describe "sms" do
      subject do
        ExternalApi::VANotifyService.send_sms_notifications(
          participant_id, notification_id, sms_template_id, first_name, docket_number, status
        )
      end
      it "sms sent successfully" do
        allow(HTTPI).to receive(:post).and_return(sms_success_response)
        expect(subject.body["template"]["id"]).to eq(sms_template_id)
      end

      context "429" do
        it "throws Caseflow::Error::VANotifyRateLimitError" do
          allow(HTTPI).to receive(:post).and_return(rate_limit_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyRateLimitError
        end
      end
    end
  end

  context "getting status of notifications" do
    subject { ExternalApi::VANotifyService.get_status(notification_id) }
    it "gets the status of an email successfully" do
      allow(HTTPI).to receive(:get).and_return(status_success_response)
      expect(subject.body.to_json).to eq(status_response_body)
    end

    context "response failure" do
      subject { ExternalApi::VANotifyService.get_status(notification_id) }
      context "fallback error code" do
        subject { ExternalApi::VANotifyService.get_status("ft54t5regf") }
        it "throws Caseflow::Error::VANotifyApiError" do
          allow(HTTPI).to receive(:get).and_return(error_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyApiError
        end
      end

      context "401" do
        it "throws Caseflow::Error::VANotifyUnauthorizedError" do
          allow(HTTPI).to receive(:get).and_return(unauthorized_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyUnauthorizedError
        end
      end

      context "403" do
        it "throws Caseflow::Error::VANotifyForbiddenError" do
          allow(HTTPI).to receive(:get).and_return(forbidden_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyForbiddenError
        end
      end

      context "404" do
        it "throws Caseflow::Error::VANotifyNotFoundError" do
          allow(HTTPI).to receive(:get).and_return(not_found_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyNotFoundError
        end
      end

      context "500" do
        let!(:error_code) { 500 }
        it "throws Caseflow::Error:VANotifyInternalServerError" do
          allow(HTTPI).to receive(:get).and_return(internal_server_error_response)
          expect { subject }.to raise_error Caseflow::Error::VANotifyInternalServerError
        end
      end
    end
  end
end
