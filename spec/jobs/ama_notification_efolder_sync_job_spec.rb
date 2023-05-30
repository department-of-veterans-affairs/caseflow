# frozen_string_literal: true

describe AmaNotificationEfolderSyncJob, type: :job do
  include ActiveJob::TestHelper
  let!(:current_user) { create(:user, roles: ["System Admin"]) }
  let!(:job) { AmaNotificationEfolderSyncJob.new }

  describe "perform" do
    before do
      Seeds::NotificationEvents.new.seed!
    end

    let!(:today) { Time.now.utc.iso8601 }
    let!(:appeals) do
      create_list(:appeal, 10, :active)
    end

    let!(:notifications) do
      appeals.each do |appeal|
        if appeal.id == appeals[3].id || appeal.id == appeals[7].id
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
    end

    let!(:make_appeals_outcoded) do
      RootTask.find_by(appeal_id: appeals[5].id).update!(status: "completed", closed_at: 2.days.ago)
      RootTask.find_by(appeal_id: appeals[6].id).update!(status: "completed", closed_at: today)
    end

    let!(:first_run_outcoded_appeals) { [appeals[6]] }
    let!(:second_run_outcoded_appeals) { [] }
    let!(:first_run_never_synced_appeals) { appeals.first(3) + [appeals[4]] + appeals.last(2) }
    let!(:second_run_never_synced_appeals) { appeals.last(2) }
    let!(:first_run_vbms_document_ids) { [appeals[6].id, appeals[0].id, appeals[1].id, appeals[2].id, appeals[4].id] }
    let!(:second_run_vbms_document_ids) { first_run_vbms_document_ids + [appeals[8].id, appeals[9].id, appeals[4].id] }

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
        expect(job.send(:ready_for_resync)).to eq([])
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
        RootTask.find_by(appeal_id: appeals[6].id).update!(closed_at: 25.hours.ago)
      end

      it "get all ama appeals that have been recently outcoded" do
        expect(job.send(:appeals_recently_outcoded)).to eq(second_run_outcoded_appeals)
      end

      it "get all ama appeals that have never been synced yet" do
        Notification.create!(
          appeals_id: appeals[4].uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: Time.zone.now,
          email_notification_status: "delivered"
        )
        create(:vbms_uploaded_document, appeal_id: appeals[4].id, appeal_type: "Appeal")
        expect(job.send(:appeals_never_synced)).to eq(second_run_never_synced_appeals)
      end

      it "get all ama appeals that must be resynced" do
        Notification.create!(
          appeals_id: appeals[4].uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: Time.zone.now,
          email_notification_status: "delivered"
        )
        create(:vbms_uploaded_document, appeal_id: appeals[4].id, appeal_type: "Appeal")
        expect(job.send(:ready_for_resync)).to eq([appeals[4]])
      end

      it "running the perform" do
        Notification.create!(
          appeals_id: appeals[4].uuid,
          appeals_type: "Appeal",
          event_date: today,
          event_type: "Appeal docketed",
          notification_type: "Email",
          notified_at: Time.zone.now,
          email_notification_status: "delivered"
        )
        create(:vbms_uploaded_document, appeal_id: appeals[4].id, appeal_type: "Appeal")

        AmaNotificationEfolderSyncJob.perform_now

        expect(
          VbmsUploadedDocument.where(document_type: "BVA Case Notifications").pluck(:appeal_id)
        ).to eq(second_run_vbms_document_ids)
      end
    end
  end
end
