# frozen_string_literal: true

describe Hearings::FetchWebexRoomMeetingDetailsJob, type: :job do
  include ActiveJob::TestHelper

  let(:room_details) do
    {
      "roomId": "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2",
      "meetingLink": "https://vadevops.webex.com/m/f3387f62-aded-46b9-8954-0b1f2c94dfd3",
      "sipAddress": "28236309135@vadevops.webex.com",
      "meetingNumber": "28236309135",
      "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
      "callInTollFreeNumber": "",
      "callInTollNumber": "+1-415-527-5035"
    }.to_json
  end
  let(:room_id) do
    "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2"
  end
  let(:meeting_title) { "221218-977_933_Hearing" }
  let(:exception) { Caseflow::Error::WebexApiError.new(code: 300, message: "Error", title: "Bad Error") }
  let(:error_details) do
    {
      error: { type: "retrieval", explanation: "retrieve details of room from Webex" },
      provider: "webex",
      api_call:
        "GET #{ENV['WEBEX_HOST_MAIN']}#{ENV['WEBEX_DOMAIN_MAIN']}#{ENV['WEBEX_API_MAIN']}rooms/#{room_id}/meetingInfo",
      response: { status: exception.code, message: exception.message }.to_json,
      room_id: room_id,
      meeting_title: meeting_title
    }
  end

  subject { described_class.perform_now(room_id: room_id, meeting_title: meeting_title) }

  context "#perform" do
    it "can run the job" do
      subject

      expect(enqueued_jobs.size).to eq(1)
      expect(enqueued_jobs.first["job_class"]).to eq("Hearings::FetchWebexRecordingsListJob")
      expect(enqueued_jobs.first["arguments"].first["meeting_id"]).to eq(JSON.parse(room_details)["meetingId"])
      expect(enqueued_jobs.first["arguments"].first["meeting_title"]).to eq(meeting_title)
    end

    it "returns correct response" do
      expect(described_class.new.send(:fetch_room_details, room_id).resp.raw_body).to eq(room_details)
    end
  end

  context "job errors" do
    before do
      allow_any_instance_of(described_class)
        .to receive(:fetch_room_details)
        .and_raise(exception)
    end

    it "retries and logs errors" do
      subject
      expect(Rails.logger).to receive(:error).at_least(:once)
      perform_enqueued_jobs { described_class.perform_later(room_id: room_id, meeting_title: meeting_title) }
    end

    it "mailer receives correct params" do
      allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).and_call_original
      expect(TranscriptionFileIssuesMailer).to receive(:issue_notification)
        .with(error_details)
      expect_any_instance_of(described_class).to receive(:log_error).once
      perform_enqueued_jobs { described_class.perform_later(room_id: room_id, meeting_title: meeting_title) }
    end

    context "mailer fails to send email" do
      it "captures external delivery error" do
        allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
          .and_raise(GovDelivery::TMS::Request::Error.new(500))
        expect_any_instance_of(described_class).to receive(:log_error).twice
        perform_enqueued_jobs { described_class.perform_later(room_id: room_id, meeting_title: meeting_title) }
      end
    end
  end
end
