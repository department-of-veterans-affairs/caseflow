# frozen_string_literal: true

describe Hearings::FetchWebexRecordingsListJob, type: :job do
  include ActiveJob::TestHelper
  let(:id) { "f91b6edce9864428af084977b7c68291_I_166641849979635652" }
  let(:title) { "221218-977_933_Hearing" }

  subject { described_class.perform_now(meeting_id: id, meeting_title: title) }

  context "job success" do
    before do
      allow_any_instance_of(Hearings::DownloadTranscriptionFileJob)
        .to receive(:perform)
        .and_return(nil)
    end

    it "Returns array of recordings objects with associated ids and host emails" do
      expect(subject.first.id).to eq("4f914b1dfe3c4d11a61730f18c0f5387")
      expect(subject.first.host_email).to eq("john.andersen@example.com")
      expect(subject.second.id).to eq("3324fb76946249cfa07fc30b3ccbf580")
      expect(subject.second.host_email).to eq("john.andersen@example.com")
      expect(subject.third.id).to eq("42b80117a2a74dcf9863bf06264f8075")
      expect(subject.third.host_email).to eq("john.andersen@example.com")
    end

    it "Uses correct api key for correct environment" do
      allow(WebexService).to receive(:new).and_call_original
      expect(WebexService).to receive(:new).with(hash_including(apikey: WebexService.access_token))
      subject
    end

    it "Uses correct query parameters" do
      allow(WebexService).to receive(:new).and_call_original
      expect(WebexService).to receive(:new)
        .with(hash_including(query: { max: 100, meetingId: id }))
      subject
    end
  end

  context "job errors" do
    let(:exception) { Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error") }
    let(:query) { "?max=100&meetingId=#{id}" }
    let(:error_details) do
      {
        error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
        provider: "webex",
        api_call:
          "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}admin/recordings/#{query}",
        response: { status: exception.code, message: exception.message }.to_json,
        meeting_id: id,
        meeting_title: title
      }
    end

    before do
      allow_any_instance_of(WebexService).to receive(:fetch_recordings_list).and_raise(exception)
    end

    it "Successfully catches errors and adds retry to queue" do
      subject
      expect(enqueued_jobs.size).to eq(1)
    end

    it "retries and logs errors" do
      subject
      expect(Rails.logger).to receive(:error).at_least(:once)
      perform_enqueued_jobs { described_class.perform_later(meeting_id: id, meeting_title: title) }
    end

    it "mailer receives correct params" do
      allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).and_call_original
      expect(TranscriptionFileIssuesMailer).to receive(:issue_notification)
        .with(error_details)
      expect_any_instance_of(described_class).to receive(:log_error).once
      perform_enqueued_jobs { described_class.perform_later(meeting_id: id, meeting_title: title) }
    end

    context "mailer fails to send email" do
      it "captures external delivery error" do
        allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
          .and_raise(GovDelivery::TMS::Request::Error.new(500))
        expect_any_instance_of(described_class).to receive(:log_error).twice
        perform_enqueued_jobs { described_class.perform_later(meeting_id: id, meeting_title: title) }
      end
    end
  end
end
