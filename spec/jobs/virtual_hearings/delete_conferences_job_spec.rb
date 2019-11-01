# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe VirtualHearings::DeleteConferencesJob, :postgres, focus: true do
  context "#perform" do
    let(:job) { VirtualHearings::DeleteConferencesJob.new }

    subject { job.perform_now }

    let(:hearing_day) do
      create(:hearing_day, regional_office: "RO42", request_type: "V", scheduled_for: Time.zone.now - 1.day)
    end
    let(:hearing) { create(:hearing, regional_office: "RO42", hearing_day: hearing_day) }

    context "for virtual hearing that has already been cleaned up" do
      let!(:virtual_hearing) do
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

    context "for virtual hearing that was cancelled" do
      let!(:virtual_hearing) do
        create(:virtual_hearing, :cancelled, hearing: hearing, conference_deleted: false)
      end

      it "updates the appropriate fields", :aggregate_failures do
        subject
        virtual_hearing.reload
        expect(virtual_hearing.conference_deleted).to eq(true)
        expect(virtual_hearing.veteran_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
        expect(virtual_hearing.judge_email_sent).to eq(true)
      end
    end
  end
end
