# frozen_string_literal: true

describe Hearings::FetchWebexRoomsListJob, type: :job do
  include ActiveJob::TestHelper

  subject { described_class.perform_now }

  # rubocop:disable Layout/LineLength
  context "perform job" do
    it "Returns the correct arrays of id and title" do
      expect(subject.length).to eq(4)
      expect(subject.first.id).to eq("Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2")
      expect(subject.first.title).to eq("Virtual Visit - 221218-977_933_Hearing-20240508 1426")
      expect(subject.second.id).to eq("Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS8zYTlhMzdiMC0wZWNiLTExZWYtYTNhZS02MTJkMjlj")
      expect(subject.second.title).to eq("Virtual Visit - 180000304_1_LegacyHearing-20240213 1712")
    end
  end
  # rubocop:enable Layout/LineLength

  context "job errors" do
    let(:query) { "?sortBy=created&max=1000" }
    let(:error_details) do
      {
        error: { type: "retrieval", explanation: "retrieve a list of rooms from Webex" },
        provider: "webex",
        api_call:
          "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}rooms#{query}",
        response: { status: 400, message: "Fake Error" }.to_json
      }
    end

    before do
      allow_any_instance_of(WebexService)
        .to receive(:fetch_rooms_list)
        .and_raise(Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error"))
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

  # The third & fourth titles returned have an invalid format
  context "filter test" do
    it "does not send an invalid title and id to the fetch room details job" do
      expect(subject.third.title).to eq("Virtual Visit - 221218-977_933_AMA-20240508 1426")
      expect(subject.fourth.title).to eq("Virtual Visit - PatientLast Problem Hearing-20240213 3123")
      subject
      expect(enqueued_jobs.size).to eq(2)
    end
  end
end
