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
  let(:event_status_sent) { "sent" }
  let(:response_body) { [{ "status" => event_status_sent }].to_json }
  let(:success_response) do
    HTTPI::Response.new(200, {}, response_body)
  end

  context "get_recipients" do
    describe "#get_recipients_from_event" do
      subject { ExternalApi::GovDeliveryService.get_recipients_from_event(email_event: email_event) }

      it "returns a list of objects" do
        allow(HTTPI).to receive(:get).and_return(success_response)

        expect(subject).to be_instance_of Array
        expect(subject.length).to eq 1
        expect(subject).to match_array JSON.parse(response_body)
      end

      context "response failure" do
        let!(:error_code) { nil }

        before do
          allow(ExternalApi::GovDeliveryService).to receive(:send_gov_delivery_request)
            .and_return(HTTPI::Response.new(error_code, {}, {}.to_json))
        end

        context "fallback error code" do
          it "throws Caseflow::Error::GovDeliveryApiError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryApiError
          end
        end

        context "401" do
          let!(:error_code) { 401 }

          it "throws Caseflow::Error::GovDeliveryUnauthorizedError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryUnauthorizedError
          end
        end

        context "403" do
          let!(:error_code) { 403 }

          it "throws Caseflow::Error::GovDeliveryForbiddenError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryForbiddenError
          end
        end

        context "404" do
          let!(:error_code) { 404 }

          it "throws Caseflow::Error::GovDeliveryNotFoundError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryNotFoundError
          end
        end

        context "500" do
          let!(:error_code) { 500 }

          it "throws Caseflow::Error::GovDeliveryInternalServerError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryInternalServerError
          end
        end

        context "502" do
          let!(:error_code) { 502 }

          it "throws Caseflow::Error::GovDeliveryBadGatewayError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryBadGatewayError
          end
        end

        context "503" do
          let!(:error_code) { 503 }

          it "throws Caseflow::Error::GovDeliveryServiceUnavailableError" do
            expect { subject }.to raise_error Caseflow::Error::GovDeliveryServiceUnavailableError
          end
        end
      end
    end

    describe "#get_sent_status_from_event" do
      subject { ExternalApi::GovDeliveryService.get_sent_status_from_event(email_event: email_event) }

      it "returns the expected value" do
        allow(HTTPI).to receive(:get).and_return(success_response)

        expect(subject).to eq event_status_sent
      end
    end
  end

  context "get message" do
    let(:message_subject) { "This is the message subject" }
    let(:body) do
      "\u003c!DOCTYPE html\u003e\n\u003chtml\u003e\n This is the message body  <br\>Sincerly Yours \u003c/html\u003e"
    end
    let(:sanitized_body) { " This is the message body\nSincerly Yours " }
    let(:response_body) { { "subject" => message_subject, "body" => body }.to_json }

    describe "#get_message_subject_and_body_from_event" do
      subject { ExternalApi::GovDeliveryService.get_message_subject_and_body_from_event(email_event: email_event) }

      it "returns the expected value" do
        allow(HTTPI).to receive(:get).and_return(success_response)

        expect(subject[:subject]).to eq message_subject
        expect(subject[:body]).to eq sanitized_body
      end
    end

    describe "#get_message_from_event" do
      subject { ExternalApi::GovDeliveryService.get_message_from_event(email_event: email_event) }

      it "returns the expected value" do
        allow(HTTPI).to receive(:get).and_return(success_response)

        expect(subject["subject"]).to eq message_subject
        expect(subject["body"]).to eq body
      end
    end
  end
end
