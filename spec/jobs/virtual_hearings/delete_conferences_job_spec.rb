# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe VirtualHearings::DeleteConferencesJob, :postgres do
  context "#perform" do
    let(:job) { VirtualHearings::DeleteConferencesJob.new }

    subject { job.perform_now }

    let(:scheduled_for) { Time.zone.now - 1.day }
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
      let(:scheduled_for) { Time.zone.now + 7.days }
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

    context "for virtual hearing that already occurred" do
      let(:scheduled_for) { Time.zone.now - 7.days }
      let!(:virtual_hearing) do
        create(:virtual_hearing, :active, hearing: hearing, conference_deleted: false)
      end

      it "updates the conference_deleted, but doesn't send emails", :aggregate_failures do
        subject
        virtual_hearing.reload
        expect(virtual_hearing.conference_deleted).to eq(true)
        expect(virtual_hearing.veteran_email_sent).to eq(false)
        expect(virtual_hearing.representative_email_sent).to eq(false)
        expect(virtual_hearing.judge_email_sent).to eq(false)
      end
    end

    context "for multiple virtual hearings, and pexip returns an error" do
      let!(:virtual_hearings) do
        [
          create(
            :virtual_hearing,
            :active,
            :initialized,
            hearing: create(:hearing, hearing_day: hearing_day),
            conference_deleted: false
          ),
          create(
            :virtual_hearing,
            :active,
            :initialized,
            hearing: create(:hearing, hearing_day: hearing_day),
            conference_deleted: false
          )
        ]
      end

      it "does not mark the virtual hearings as deleted" do
        fake_service = PexipService.new
        expect(fake_service).to(
          receive(:delete_conference)
            .twice
            .and_return(ExternalApi::PexipService::DeleteResponse.new(HTTPI::Response.new(400, {}, {})))
        )
        expect(job).to(
          receive(:pexip_service).twice.and_return(fake_service)
        )
        subject
        virtual_hearings.each(&:reload)
        expect(virtual_hearings.map(&:conference_deleted)).to all(be == false)
      end

      it "assumes a 404 means the virtual hearing confernece was already deleted" do
        fake_service = PexipService.new
        expect(fake_service).to(
          receive(:delete_conference)
            .twice
            .and_return(ExternalApi::PexipService::DeleteResponse.new(HTTPI::Response.new(404, {}, {})))
        )
        expect(job).to(
          receive(:pexip_service).twice.and_return(fake_service)
        )
        subject
        virtual_hearings.each(&:reload)
        expect(virtual_hearings.map(&:conference_deleted)).to all(be == true)
      end
    end
  end
end
