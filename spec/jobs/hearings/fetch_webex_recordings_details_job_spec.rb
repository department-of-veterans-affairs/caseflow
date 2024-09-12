# frozen_string_literal: true

describe Hearings::FetchWebexRecordingsDetailsJob, type: :job do
  include ActiveJob::TestHelper
  let(:id) { "4f914b1dfe3c4d11a61730f18c0f5387" }
  let(:email) { "john.andersen@example.com" }
  let(:meeting_title) { "180000304_1_LegacyHearing" }
  let(:mp4_link) { "https://www.learningcontainer.com/mp4-sample-video-files-download/#" }
  let(:mp3_link) { "https://freetestdata.com/audio-files/mp3/" }
  let(:vtt_link) { "https://www.capsubservices.com/assets/downloads/web/WebVTT.vtt" }
  let(:topic) { "Webex meeting-20240520 2030-1" }
  let(:mp4_file_name) { "180000304_1_LegacyHearing-1.mp4" }
  let(:vtt_file_name) { "180000304_1_LegacyHearing-1.vtt" }
  let(:mp3_file_name) { "180000304_1_LegacyHearing-1.mp3" }

  subject { described_class.perform_now(recording_id: id, host_email: email, meeting_title: meeting_title) }

  context "method testing" do
    before do
      allow_any_instance_of(Hearings::DownloadTranscriptionFileJob)
        .to receive(:perform)
        .and_return(nil)
    end

    it "Uses correct api key for correct environment" do
      allow(WebexService).to receive(:new).and_call_original
      expect(WebexService).to receive(:new).with(hash_including(apikey: WebexService.access_token))
      subject
    end

    it "hits the webex API and returns recording details" do
      get_details = Hearings::FetchWebexRecordingsDetailsJob.new
      run = get_details.send(:fetch_recording_details, id, email)

      expect(run.mp4_link).to eq(mp4_link)
      expect(run.mp3_link).to eq(mp3_link)
      expect(run.vtt_link).to eq(vtt_link)
    end

    it "names the files correctly" do
      get_details = Hearings::FetchWebexRecordingsDetailsJob.new
      run_mp4 = get_details.send(:create_file_name, topic, "mp4", meeting_title)
      run_vtt = get_details.send(:create_file_name, topic, "vtt", meeting_title)
      run_mp3 = get_details.send(:create_file_name, topic, "mp3", meeting_title)

      expect(run_mp4).to eq(mp4_file_name)
      expect(run_vtt).to eq(vtt_file_name)
      expect(run_mp3).to eq(mp3_file_name)
    end
  end

  context "job errors" do
    let(:exception) { Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error") }
    let(:query) { "?hostEmail=#{email}" }
    let(:error_details) do
      {
        error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
        provider: "webex",
        api_call:
          "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}recordings/#{id}#{query}",
        response: { status: exception.code, message: exception.message }.to_json,
        recording_id: id,
        host_email: email,
        meeting_title: meeting_title
      }
    end

    before do
      allow_any_instance_of(WebexService)
        .to receive(:fetch_recording_details)
        .and_raise(exception)
    end

    it "Successfully catches errors and adds to retry queue" do
      subject
      expect(enqueued_jobs.size).to eq(1)
    end

    it "retries and logs errors" do
      subject
      expect(Rails.logger).to receive(:error).at_least(:once)
      perform_enqueued_jobs do
        described_class.perform_later(
          recording_id: id,
          host_email: email,
          meeting_title: meeting_title
        )
      end
    end

    it "mailer receives correct params" do
      allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).and_call_original
      expect(TranscriptionFileIssuesMailer).to receive(:issue_notification)
        .with(error_details)
      expect_any_instance_of(described_class).to receive(:log_error).once
      perform_enqueued_jobs do
        described_class.perform_later(
          recording_id: id,
          host_email: email,
          meeting_title: meeting_title
        )
      end
    end

    context "mailer fails to send email" do
      it "captures external delivery error" do
        allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
          .and_raise(GovDelivery::TMS::Request::Error.new(500))
        expect_any_instance_of(described_class).to receive(:log_error).twice
        perform_enqueued_jobs do
          described_class.perform_later(
            recording_id: id,
            host_email: email,
            meeting_title: meeting_title
          )
        end
      end
    end
  end
end
