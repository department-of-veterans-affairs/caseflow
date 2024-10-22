# frozen_string_literal: true

describe Hearings::CreateNonVirtualConferenceJob, type: :job do
  include ActiveJob::TestHelper
  let(:nyc_ro_eastern) { "RO06" }
  let(:video_type) { HearingDay::REQUEST_TYPES[:video] }
  let(:hearing_day) { create(:hearing_day, regional_office: nyc_ro_eastern, request_type: video_type) }
  let!(:hearing) do
    create(:hearing, hearing_day: hearing_day).tap do |hearing|
      hearing.meeting_type.update(service_name: "webex")
    end
  end

  subject { described_class.perform_now(hearing: hearing) }

  context "Non Virtual Hearing" do
    it "creates a conference for the hearing" do
      subject
      conference_link = ConferenceLink.find_by(hearing_id: hearing.id)
      expect(conference_link.hearing_id).to eq(hearing.id)
    end
  end

  context "job errors" do
    before do
      allow_any_instance_of(WebexService)
        .to receive(:create_conference)
        .with(hearing)
        .and_raise(Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error"))
    end

    it "Successfully catches errors and adds to retry queue" do
      subject
      expect(enqueued_jobs.size).to eq(1)
    end

    it "retries and logs errors" do
      subject
      expect(Rails.logger).to receive(:error).twice
      perform_enqueued_jobs { described_class.perform_later(hearing: hearing) }
    end
  end
end
