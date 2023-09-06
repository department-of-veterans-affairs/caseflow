# frozen_string_literal: true

describe VirtualHearings::DeleteConferenceLinkJob do
  include ActiveJob::TestHelper

  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:judge) { Judge.new(create(:user)) }

  let!(:single_hearing_day) do
    create(:hearing_day,
    id: 1,
    created_by: current_user,
    judge_id: judge,
    regional_office: "RO17",
    request_type: "V",
    room: (1..7).to_s,
    scheduled_for: Date.new(2023, 9, 4))
  end

  let(:hearing_days_test_collection) do
    create(:hearing_day,
           id: 1,
           created_by: current_user,
           judge_id: judge,
           regional_office: "RO17",
           request_type: "V",
           room: (1..7).to_s,
           scheduled_for: Date.new(2023, 9, 4))
    create(:hearing_day,
           id: 2,
           created_by: current_user,
           judge_id: judge,
           regional_office: "RO17",
           request_type: "V",
           room: (1..7).to_s,
           scheduled_for: Date.new(2023, 9, 1))
    create(:hearing_day,
           id: 3,
           created_by: current_user,
           judge_id: judge,
           regional_office: "RO17",
           request_type: "V",
           room: (1..7).to_s,
           scheduled_for: Date.new(2023, 8, 31))
    create(:hearing_day,
           id: 4,
           created_by: current_user,
           judge_id: judge,
           regional_office: "RO17",
           request_type: "V",
           room: (1..7).to_s,
           scheduled_for: Date.new(2023, 9, 8))
    create(:hearing_day,
           id: 5,
           created_by: current_user,
           judge_id: judge,
           regional_office: "RO17",
           request_type: "V",
           room: (1..7).to_s,
           scheduled_for: Date.new(2023, 9, 8))
  end

  let(:conf_link_test_collection) do
    create(:conference_link,
           hearing_day_id: 1,
           guest_pin_long: "6393596604",
           created_at: Time.zone.now)
    create(:conference_link,
           hearing_day_id: 2,
           guest_pin_long: "6393596604",
           created_at: Time.zone.now)
    create(:conference_link,
           hearing_day_id: 3,
           guest_pin_long: "6393596604",
           created_at: Time.zone.now)
    create(:conference_link,
           hearing_day_id: 4,
           guest_pin_long: "6393596604",
           created_at: Time.zone.now)
    create(:conference_link,
           hearing_day_id: 5,
           guest_pin_long: "6393596604",
           created_at: Time.zone.now)
  end

  context ".perform" do
    subject(:job) { VirtualHearings::DeleteConferenceLinkJob.perform_later }
    it "Calls the retrieve_stale_conference_links" do
      hearing_days_test_collection
      byebug
      conf_link_test_collection
      expect(job).to receive(:retreive_stale_conference_links)
      job.perform
    end
  end
end
