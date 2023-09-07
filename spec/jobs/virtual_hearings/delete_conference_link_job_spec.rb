# frozen_string_literal: true

describe VirtualHearings::DeleteConferenceLinkJob do
  include ActiveJob::TestHelper

  let!(:current_user) { create(:user, roles: ["System Admin"]) }
  let!(:judge) { Judge.new(create(:user)) }
  let!(:single_hearing_day) { FactoryBot.create(:hearing_day) }

  let!(:future_hearing_day_with_link) { FactoryBot.create(:hearing_day, :virtual, :future_with_link) }
  let!(:past_hearing_day_with_link) { FactoryBot.create(:hearing_day, :virtual, :past_with_link) }

  context ".perform" do
    # subject(:job) { VirtualHearings::DeleteConferenceLinkJob.new }
    it "When conference links in the DB are past the date of the date the job is run" do
      expect(ConferenceLink.count).to be(2)
      perform_enqueued_jobs { VirtualHearings::DeleteConferenceLinkJob.perform_now }
      expect(ConferenceLink.count).to be(1)
    end
  end
end
