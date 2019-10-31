# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe VirtualHearings::DeleteConferencesJob, :postgres, focus: true do
  context "#perform" do
    let(:job) { VirtualHearings::DeleteConferencesJob.new }

    subject { job.perform_now }

    let(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.now - 1.day) }
    let(:hearing) { create(:hearing, hearing_day: hearing_day) }

    context "for virtual hearing that has already been cleaned up" do
      let(:virtual_hearing) do
        create(
          :virtual_hearing,
          hearing: hearing,
          conference_deleted: true,
          veteran_email_sent: true,
          representative_email_sent: true,
          judge_email_sent: true
        )
      end

      it "runs but does nothing" do
        expect(job).not_to receive(:delete_conference)
        subject
      end
    end
  end
end
