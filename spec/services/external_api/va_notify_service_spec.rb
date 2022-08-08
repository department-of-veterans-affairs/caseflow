# frozen_string_literal: true

describe ExternalApi::VANotifyService do
    let(:va_notify_url) { "fake.tms.vanotify.com" }
    let(:auth_token) { "SOME-FAKE-TOKEN" }
    let(:cert_file_location) { "/path/to/cert/file" }
  
    before do
      stub_const("ENV", "VANotify_SERVER" => va_notify_url)
      stub_const("ENV", "VANotify_TOKEN" => auth_token)
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
    let(:empty_response) do
      HTTPI::Response.new(200, {}, [].to_json)
    end
  
    context "get_recipients" do
      describe "#get_recipients_from_event" do
        subject { ExternalApi::VANotifyService.get_recipients_from_event(email_event: email_event) }
  
        it "returns a list of objects" do
          allow(HTTPI).to receive(:get).and_return(success_response)
  
          expect(subject).to be_instance_of Array
          expect(subject.length).to eq 1
          expect(subject).to match_array JSON.parse(response_body)
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
  
          context "500" do
            let!(:error_code) { 500 }
  
            it "throws Caseflow::Error::VANotifyInternalServerError" do
              expect { subject }.to raise_error Caseflow::Error::VANotifyInternalServerError
            end
          end
  
          context "502" do
            let!(:error_code) { 502 }
  
            it "throws Caseflow::Error::VANotifyBadGatewayError" do
              expect { subject }.to raise_error Caseflow::Error::VANotifyBadGatewayError
            end
          end
  
          context "503" do
            let!(:error_code) { 503 }
  
            it "throws Caseflow::Error::VANotifyServiceUnavailableError" do
              expect { subject }.to raise_error Caseflow::Error::VANotifyServiceUnavailableError
            end
          end
        end
      end

      describe '#send_notifications' do 
        it "it sends the notifications from VANotifyService"
        result = VANotifyService.send_notifications()
        
        expect(result.error).to eq()
        expect(result.error).to_not be_falsey

        end
    end

    describe '#get_status' do 
        it "it returns the status from the get"
        result = VANotifyService.get_status(notification_id)


        expect(result.error).to eq(:notification_id)
        expect(result.error).to_not be_nil

        end
    end

    describe '#create_callback' do 
        it "returns the information generated from creating the callback"
        result = VANotifyService.create_callback(url, callback_type, bearer_token, callback_channel)

        expect(result.error).to eq(url, callback_type, bearer_token, callback_channel)

        end
    end

    describe '#get_callback' do 
        it "returns the information from the Get for creating the callback"
        result = VANotifyService.get_callback(send_va_notify_request(request))

        expect(result.error).to eq(send_va_notify_request(request))
        expect(result.error).to_not be_nil

        end
    end
  
      describe "#get_sent_status_from_event" do
        subject { ExternalApi::VANotifyService.get_sent_status_from_event(email_event: email_event) }
  
        it "returns the expected value" do
          allow(HTTPI).to receive(:get).and_return(success_response)
  
          expect(subject).to eq event_status_sent
        end
  
        context "with an empty response" do
          it "returns nil" do
            allow(HTTPI).to receive(:get).and_return(empty_response)
  
            expect(subject).to be_nil
          end
        end
      end
    end
  
    context "get message" do
      let(:message_subject) { "This is the message subject" }
      let(:body) do
        "\u003c!DOCTYPE html\u003e\n\u003chtml\u003e\n This is the message body  " \
        "\u003cbr\u003eSincerly Yours \u003c/html\u003e"
      end
      let(:sanitized_body) { " This is the message body\nSincerly Yours " }
      let(:response_body) { { "subject" => message_subject, "body" => body }.to_json }
  
      describe "#get_message_subject_and_body_from_event" do
        subject { ExternalApi::VANotifyService.get_message_subject_and_body_from_event(email_event: email_event) }
  
        it "returns the expected value" do
          allow(HTTPI).to receive(:get).and_return(success_response)
  
          expect(subject[:subject]).to eq message_subject
          expect(subject[:body]).to eq sanitized_body
        end
      end
  
      describe "#get_message_from_event" do
        subject { ExternalApi::VANotifyService.get_message_from_event(email_event: email_event) }
  
        it "returns the expected value" do
          allow(HTTPI).to receive(:get).and_return(success_response)
  
          expect(subject["subject"]).to eq message_subject
          expect(subject["body"]).to eq body
        end
      end
    end
  end