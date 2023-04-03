# frozen_string_literal: true

describe AmaNotificationEfolderSyncJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }

  describe "perform" do
    # rubocop:disable Style/BlockDelimiters
    let(:today) { Time.now.utc.iso8601 }
    let(:appeals) {
      create_list(:appeal, 10)
    }
    let(:notifications) {
      appeals.each do |appeal|
        if appeal.id == 4 || appeal.id == 8
          next
        end

        Notification.create!(
          appeals_id: appeal.uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: today
        )
      end
    }
    let(:make_appeals_outcoded) {
      BvaDispatchTask.find(appeal_id: 6, assigned_to_type: "User").update!(status: "completed", closed_at: 2.days.ago)
      BvaDispatchTask.find(appeal_id: 6, assigned_to_type: "Organization").update!(status: "completed", closed_at: 2.days.ago)
      BvaDispatchTask.find(appeal_id: 7, assigned_to_type: "User").update!(status: "completed", closed_at: today )
      BvaDispatchTask.find(appeal_id: 7, assigned_to_type: "Organization").update!(status: "completed", closed_at: today)
    }
    let(:first_run_outcoded_appeals) { [Appeal.find(7)] }
    let(:second_run_outcoded_appeals) { [Appeal.find(7)] }
    let(:first_run_never_synced_appeals) { Appeal.first(5) + Appeal.last(2) }
    let(:second_run_never_synced_appeals) { Appeal.last(2) }
    let(:first_run_prev_synced_appeals) { [] }
    let(:second_run_prev_synced_appeals) { Appeal.first(5) }
    let(:first_run_vbms_documents) { Appeal.first(5) }
    let(:second_run_vbms_documents) { first_run_vbms_documents + Appeal.last(2) }

    before do
      AmaNotificationEfolderSyncJob::BATCH_LIMIT = 5
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
