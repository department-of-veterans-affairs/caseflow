# frozen_string_literal: true

describe Hearings::FetchWebexRoomMeetingDetailsJob, type: :job do
  include ActiveJob::TestHelper

  let(:room_details) do
    {
      "roomId": "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2",
      "meetingLink": "https://vadevops.webex.com/m/f3387f62-aded-46b9-8954-0b1f2c94dfd3",
      "sipAddress": "28236309135@vadevops.webex.com",
      "meetingNumber": "28236309135",
      "meetingId": "a52e152a05114cfcb5c7b5e6c088fcc0",
      "callInTollFreeNumber": "",
      "callInTollNumber": "+1-415-527-5035"
    }.to_json
  end
  let(:room_id) { "YhOGfIvifid8996hlfsHo28F" }
  let(:meeting_title) { "fake meeting" }
  let(:subject) do
    described_class
  end
  let(:exception) { Caseflow::Error::WebexApiError.new(code: 300, message: "Error", title: "Bad Error") }

  describe "#perform" do
    it "can run the job" do
      allow_any_instance_of(Hearings::FetchWebexRecordingsListJob).to receive(:perform).and_return([])
      expect_any_instance_of(described_class)
        .to receive(:fetch_room_details).and_return([])
      subject.perform_now(room_id: room_id, meeting_title: meeting_title)
    end

    it "returns correct response" do
      expect(subject.new.send(:fetch_room_details, room_id).resp.raw_body).to eq(room_details)
    end

    it "retries and logs errors" do
      allow_any_instance_of(described_class)
        .to receive(:fetch_room_details)
        .and_raise(exception)

      expect(Rails.logger).to receive(:error).at_least(:once)
      perform_enqueued_jobs { described_class.perform_later(room_id: room_id, meeting_title: meeting_title) }
    end
  end
end
