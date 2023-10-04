# frozen_string_literal: true

describe VirtualHearings::DeleteConferenceLinkJob, :all_dbs do
  include ActiveJob::TestHelper

  let!(:current_user) { create(:user, roles: ["System Admin"]) }
  let!(:judge) { Judge.new(create(:user)) }

  before do
    allow_any_instance_of(VirtualHearings::LinkService).to receive(:pin_key).and_return("mysecretkey")
    allow_any_instance_of(VirtualHearings::LinkService).to receive(:host).and_return("example.va.gov")
    allow_any_instance_of(VirtualHearings::LinkService).to receive(:path).and_return("/sample")
  end

  describe ".perform" do
    context "When conference links in the DB are past the date of the date the job is run" do
      let!(:future_hearing_day_with_link) { create(:hearing_day, :virtual, :future_with_link) }
      let!(:past_hearing_day_with_link) { create(:hearing_day, :virtual, :past_with_link) }

      it "Soft deletes the qualifying links." do
        expect(ConferenceLink.count).to be(2)
        perform_enqueued_jobs { VirtualHearings::DeleteConferenceLinkJob.perform_now }
        expect(ConferenceLink.count).to be(1)
        expect(ConferenceLink.all.pluck(:id)).not_to include(2)
      end
    end
  end
end
