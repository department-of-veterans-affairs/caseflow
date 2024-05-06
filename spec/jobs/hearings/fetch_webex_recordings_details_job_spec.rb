# frozen_string_literal: true

describe Hearings::FetchWebexRecordingsDetailsJob, type: :job do
  include ActiveJob::TestHelper
  let(:id) { "4f914b1dfe3c4d11a61730f18c0f5387" }
  let(:mp4_link) { "https://www.learningcontainer.com/mp4-sample-video-files-download/#" }
  let(:mp3_link) { "https://freetestdata.com/audio-files/mp3/" }
  let(:vtt_link) { "https://www.capsubservices.com/assets/downloads/web/WebVTT.vtt" }
  let(:topic) { "Virtual Visit - 180000304_1_LegacyHearing-20240213 1712-1" }
  let(:mp4_file_name) { "180000304_1_LegacyHearing-1.mp4" }
  let(:vtt_file_name) { "180000304_1_LegacyHearing-1.vtt" }
  let(:mp3_file_name) { "180000304_1_LegacyHearing-1.mp3" }
  let(:hearing) { create(:hearing) }
  let(:file_name) { "#{hearing.docket_number}_#{hearing.id}_#{hearing.class}" }
  let(:access_token) { "sample_#{Rails.deploy_env}_token" }

  subject { described_class.perform_now(id: id, file_name: file_name) }

  before do
    allow(CredStash).to receive(:get).with("webex_#{Rails.deploy_env}_access_token").and_return(access_token)
  end

  context "method testing" do
    before do
      allow_any_instance_of(Hearings::DownloadTranscriptionFileJob)
        .to receive(:perform)
        .and_return(nil)
    end

    it "Uses correct api key for correct environment" do
      allow(WebexService).to receive(:new).and_call_original
      expect(WebexService).to receive(:new).with(hash_including(apikey: access_token))
      subject
    end

    it "hits the webex API and returns recording details" do
      get_details = Hearings::FetchWebexRecordingsDetailsJob.new
      run = get_details.send(:fetch_recording_details, id)

      expect(run.mp4_link).to eq(mp4_link)
      expect(run.mp3_link).to eq(mp3_link)
      expect(run.vtt_link).to eq(vtt_link)
      expect(run.topic).to eq(topic)
    end

    it "names the files correctly" do
      get_details = Hearings::FetchWebexRecordingsDetailsJob.new
      run_mp4 = get_details.send(:create_file_name, topic, "mp4")
      run_vtt = get_details.send(:create_file_name, topic, "vtt")
      run_mp3 = get_details.send(:create_file_name, topic, "mp3")

      expect(run_mp4).to eq(mp4_file_name)
      expect(run_vtt).to eq(vtt_file_name)
      expect(run_mp3).to eq(mp3_file_name)
    end
  end

  context "job errors" do
    let(:exception) { Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error") }
    let(:error_details) do
      {
        error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
        provider: "webex",
        recording_id: id,
        api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}/#{id}",
        response: { status: exception.code, message: exception.message }.to_json,
        docket_number: nil
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
      perform_enqueued_jobs { described_class.perform_later(id: id, file_name: file_name) }
    end

    it "mailer receives correct params" do
      allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).and_call_original
      expect(TranscriptionFileIssuesMailer).to receive(:issue_notification)
        .with(error_details)
      expect_any_instance_of(described_class).to receive(:log_error).once
      perform_enqueued_jobs { described_class.perform_later(id: id, file_name: file_name) }
    end

    context "mailer fails to send email" do
      it "captures external delivery error" do
        allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
          .and_raise(GovDelivery::TMS::Request::Error.new(500))
        expect_any_instance_of(Hearings::WebexTranscriptionFilesProcessJob).to receive(:log_error).twice
        perform_enqueued_jobs { described_class.perform_later(id: id, file_name: file_name) }
      end
    end
  end
end
