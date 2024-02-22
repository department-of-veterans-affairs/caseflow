# frozen_string_literal: true

describe Hearings::GetWebexRecordingsDetailsJob, type: :job do
  include ActiveJob::TestHelper
  let(:id) { "4f914b1dfe3c4d11a61730f18c0f5387" }
  let(:mp4_link) { "https://www.learningcontainer.com/mp4-sample-video-files-download/#" }
  let(:mp3_link) { "https://freetestdata.com/audio-files/mp3/" }
  let(:vtt_link) { "https://www.capsubservices.com/assets/downloads/web/WebVTT.vtt" }
  let(:topic) { "Virtual Visit - 180000304_1_LegacyHearing-20240213 1712-1" }
  let(:mp4_file_name) { "180000304_1_LegacyHearing-1.mp4" }
  let(:vtt_file_name) { "180000304_1_LegacyHearing-1.vtt" }
  let(:mp3_file_name) { "180000304_1_LegacyHearing-1.mp3" }

  subject { described_class.perform_now(id: id) }

  context "method testing" do
    before do
      allow_any_instance_of(Hearings::DownloadTranscriptionFileJob)
        .to receive(:perform)
        .and_return(nil)
    end

    it "hits the webex API and returns recording details" do
      get_details = Hearings::GetWebexRecordingsDetailsJob.new
      run = get_details.send(:get_recording_details, id)
      expect(subject).to be(nil)

      expect(run.mp4_link).to eq(mp4_link)
      expect(run.mp3_link).to eq(mp3_link)
      expect(run.vtt_link).to eq(vtt_link)
      expect(run.topic).to eq(topic)
    end

    it "names the files correctly" do
      get_details = Hearings::GetWebexRecordingsDetailsJob.new
      run_mp4 = get_details.send(:create_file_name, topic, "mp4")
      run_vtt = get_details.send(:create_file_name, topic, "vtt")
      run_mp3 = get_details.send(:create_file_name, topic, "mp3")
      expect(subject).to be(nil)

      expect(run_mp4).to eq(mp4_file_name)
      expect(run_vtt).to eq(vtt_file_name)
      expect(run_mp3).to eq(mp3_file_name)
    end
  end

  context "job errors" do
    before do
      allow_any_instance_of(WebexService)
        .to receive(:get_recording_details)
        .and_raise(Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error"))
    end

    it "Successfully catches errors and adds to retry queue" do
      subject
      expect(enqueued_jobs.size).to eq(1)
    end

    it "retries and logs errors" do
      subject
      expect(Rails.logger).to receive(:error).with(/Retrying/)
      perform_enqueued_jobs { described_class.perform_later(id: id) }
    end
  end
end
