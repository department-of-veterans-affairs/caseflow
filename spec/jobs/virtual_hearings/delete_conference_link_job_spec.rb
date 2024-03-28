# frozen_string_literal: true

describe VirtualHearings::DeleteConferenceLinkJob, :all_dbs do
  include ActiveJob::TestHelper

  let!(:current_user) { create(:user, roles: ["System Admin"]) }
  let!(:judge) { Judge.new(create(:user)) }

  subject { perform_enqueued_jobs { VirtualHearings::DeleteConferenceLinkJob.perform_now } }

  describe ".perform" do
    context "When conference links in the DB are past the date of the date the job is run" do
      let!(:future_hearing_day_with_link) { create(:hearing_day, :virtual, :future_with_link) }
      let!(:past_hearing_day_with_link) { create(:hearing_day, :virtual, :past_with_link) }

      it "Soft deletes the qualifying links." do
        expect { subject }.to change { ConferenceLink.count }.by(-1)
        expect(ConferenceLink.pluck(:id)).not_to include(past_hearing_day_with_link.id)
      end
    end
  end
end
