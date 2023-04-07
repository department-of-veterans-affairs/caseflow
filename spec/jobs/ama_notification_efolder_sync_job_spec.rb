# frozen_string_literal: true

describe AmaNotificationEfolderSyncJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:job) { AmaNotificationEfolderSyncJob.new }

  describe "perform" do
    before do
      Seeds::NotificationEvents.new.seed!
    end

    # rubocop:disable Style/BlockDelimiters
    let(:today) { Time.now.utc.iso8601 }
    let(:appeals) {
      create_list(:appeal, 10, :active)
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
          notified_at: today,
          email_notification_status: "delivered"
        )
      end
    }
    let(:make_appeals_outcoded) {
      RootTask.find_by(appeal_id: 6).update!(status: "completed", closed_at: 2.days.ago)
      RootTask.find_by(appeal_id: 7).update!(status: "completed", closed_at: today)
    }
    let(:first_run_outcoded_appeals) { [Appeal.find(7)] }
    let(:second_run_outcoded_appeals) { [] }
    let(:first_run_never_synced_appeals) { Appeal.first(3) + Appeal.where(id: 5) + Appeal.last(2) }
    let(:second_run_never_synced_appeals) { Appeal.last(2) }
    let(:first_run_ready_for_resync) { [] }
    let(:second_run_ready_for_resync) { Appeal.where(id: 7) + Appeal.first(3) + Appeal.where(id: 5) }
    let(:first_run_vbms_document_ids) { [7, 1, 2, 3, 5] }
    let(:second_run_vbms_document_ids) { first_run_vbms_document_ids + [9, 10, 5] }
    let(:run_job) { AmaNotificationEfolderSyncJob.perform_now }
    # rubocop:enable Style/BlockDelimiters

    before do
      AmaNotificationEfolderSyncJob::BATCH_LIMIT = 5
      notifications
      make_appeals_outcoded
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    context "first run" do
      it "get all ama appeals that have been recently outcoded" do
        expect(job.send(:appeals_recently_outcoded)).to eq(first_run_outcoded_appeals)
      end

      it "get all ama appeals that have never been synced yet" do
        expect(job.send(:appeals_never_synced)).to eq(first_run_never_synced_appeals)
      end

      it "get all ama appeals that must be resynced" do
        expect(job.send(:ready_for_resync)).to eq(first_run_ready_for_resync)
      end

      it "running the perform" do
        AmaNotificationEfolderSyncJob.perform_now
        expect(VbmsUploadedDocument.first(5).pluck(:appeal_id)).to eq(first_run_vbms_document_ids)
      end
    end

    context "second run" do
      before do
        perform_enqueued_jobs do
          AmaNotificationEfolderSyncJob.perform_now
        end
        RootTask.find_by(appeal_id: 7).update!(closed_at: 25.hours.ago)
      end

      it "get all ama appeals that have been recently outcoded" do
        expect(job.send(:appeals_recently_outcoded)).to eq(second_run_outcoded_appeals)
      end

      it "get all ama appeals that have never been synced yet" do
        Notification.create!(
          appeals_id: Appeal.find(5).uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: Time.zone.now,
          email_notification_status: "delivered"
        )
        expect(job.send(:appeals_never_synced)).to eq(second_run_never_synced_appeals)
      end

      it "get all ama appeals that must be resynced" do
        Notification.create!(
          appeals_id: Appeal.find(5).uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: Time.zone.now,
          email_notification_status: "delivered"
        )
        expect(job.send(:ready_for_resync)).to eq([Appeal.find(5)])
      end

      it "running the perform" do
        Notification.create!(
          appeals_id: Appeal.find(5).uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: Time.zone.now,
          email_notification_status: "delivered"
        )
        AmaNotificationEfolderSyncJob.perform_now
        expect(VbmsUploadedDocument.pluck(:appeal_id)).to eq(second_run_vbms_document_ids)
      end
    end
  end
end
