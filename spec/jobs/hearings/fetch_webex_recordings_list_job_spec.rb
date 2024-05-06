# frozen_string_literal: true

describe Hearings::FetchWebexRecordingsListJob, type: :job do
  include ActiveJob::TestHelper
  let(:access_token) { "sample_#{Rails.deploy_env}_token" }
  let(:from_param) { 2.hours.ago.in_time_zone("America/New_York").beginning_of_hour }
  let(:to_param) { 1.hour.ago.in_time_zone("America/New_York").beginning_of_hour }

  subject { described_class.perform_now }

  before do
    allow(CredStash).to receive(:get).with("webex_#{Rails.deploy_env}_access_token").and_return(access_token)
  end

  context "job success" do
    before do
      allow_any_instance_of(Hearings::DownloadTranscriptionFileJob)
        .to receive(:perform)
        .and_return(nil)
    end

    it "Returns the correct array of ids" do
      expect(subject).to eq(%w[
                              4f914b1dfe3c4d11a61730f18c0f5387
                              3324fb76946249cfa07fc30b3ccbf580
                              42b80117a2a74dcf9863bf06264f8075
                            ])
    end

    it "Uses correct api key for correct environment" do
      allow(WebexService).to receive(:new).and_call_original
      expect(WebexService).to receive(:new).with(hash_including(apikey: access_token))
      subject
    end

    it "Uses correctly formatted to and from query parameters" do
      allow(WebexService).to receive(:new).and_call_original
      expect(WebexService).to receive(:new)
        .with(hash_including(query: { to: to_param.iso8601, from: from_param.iso8601, max: 100 }))
      subject
    end
  end

  context "job errors" do
    let(:exception) { Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error") }
    let(:query) { "?max=100?from=#{CGI.escape(from_param.iso8601)}?to=#{CGI.escape(to_param.iso8601)}" }
    let(:error_details) do
      {
        error: { type: "retrieval", explanation: "retrieve a list of recordings from Webex" },
        provider: "webex",
        api_call: "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}#{query}",
        response: { status: exception.code, message: exception.message }.to_json,
        times: { from: from_param, to: to_param },
        docket_number: nil
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
      perform_enqueued_jobs { described_class.perform_later }
    end

    it "mailer receives correct params" do
      allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).and_call_original
      expect(TranscriptionFileIssuesMailer).to receive(:issue_notification)
        .with(error_details)
      expect_any_instance_of(described_class).to receive(:log_error).once
      perform_enqueued_jobs { described_class.perform_later }
    end

    context "mailer fails to send email" do
      it "captures external delivery error" do
        allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
          .and_raise(GovDelivery::TMS::Request::Error.new(500))
        expect_any_instance_of(described_class).to receive(:log_error).twice
        perform_enqueued_jobs { described_class.perform_later }
      end
    end
  end
end
