# frozen_string_literal: true

describe LegacyNotificationEfolderSyncJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }

  before do
    Seeds::NotificationEvents.new.seed!
  end

  describe "perform" do
    # rubocop:disable Style/BlockDelimiters
    let(:today) { Time.now.utc.iso8601 }
    let(:appeals) {
      create_list(:legacy_appeal, 10)
    }
    let(:notifications) {
      appeals.each do |appeal|
        if appeal.id == 4 || appeal.id == 8
          next
        end

        Notification.create!(
          appeals_id: appeal.vacols_id,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: today
        )
      end
    }

    let(:make_appeals_outcoded) {
      RootTask.find(appeal_id: 6).update!(status: "completed", closed_at: 2.days.ago)
      RootTask.find(appeal_id: 7).update!(status: "completed", closed_at: today)
    }

    let(:first_run_outcoded_appeals) { [LegacyAppeal.find(7)] }
    let(:second_run_outcoded_appeals) { [] }
    let(:first_run_never_synced_appeals) { LegacyAppeal.first(5) + LegacyAppeal.last(2) }
    let(:second_run_never_synced_appeals) { LegacyAppeal.last(2) }
    let(:first_run_prev_synced_appeals) { [] }
    let(:second_run_prev_synced_appeals) { LegacyAppeal.first(5) }
    let(:first_run_vbms_documents) { LegacyAppeal.first(5) }
    let(:second_run_vbms_documents) { first_run_vbms_documents + LegacyAppeal.last(2) }
    # rubocop:enable Style/BlockDelimiters

    before do
      LegacyNotificationEfolderSyncJob::BATCH_LIMIT = 5
      notifications
      make_appeals_outcoded
    end

    context "first run" do
      it "get all ama appeals that have been recently outcoded" do
        expect((job.send(:appeals_recently_outcoded).to eq(first_run_outcoded_appeals)))
      end

      it "get all ama appeals that have never been synced yet" do
        expect((job.send(:appeals_never_synced).to eq(first_run_never_synced_appeals)))
      end

      it "get all ama appeals that have already been synced previously" do
        expect((job.send(:previously_synced_appeals).to eq(first_run_prev_synced_appeals)))
      end

      it "running the perform" do
        expect((job.perform_now.to eq(first_run_vbms_documents)))
      end
    end

    context "second run" do
      before do
        RootTask.find(appeal_id: 7).update!(closed_at: 25.hours.ago)
      end
      it "get all ama appeals that have been recently outcoded" do
        expect((job.send(:appeals_recently_outcoded).to eq(second_run_outcoded_appeals)))
      end

      it "get all ama appeals that have never been synced yet" do
        expect((job.send(:appeals_never_synced).to eq(second_run_never_synced_appeals)))
      end

      it "get all ama appeals that have already been synced previously" do
        expect((job.send(:previously_synced_appeals).to eq(second_run_prev_synced_appeals)))
      end

      it "running the perform" do
        expect((job.perform_now.to eq(second_run_vbms_documents)))
      end
    end
  end
end
