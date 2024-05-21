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
    Hearings::FetchWebexRoomMeetingDetailsJob.perform_now(room_id: room_id, meeting_title: meeting_title)
  end

  describe "#perform" do
    it "fetches correct response" do
      expect_any_instance_of(Hearings::FetchWebexRoomMeetingDetailsJob)
        .to receive(:fetch_room_details).with(room_id).and_return([])
      subject
    end
  end
end
