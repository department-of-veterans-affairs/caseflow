# frozen_string_literal: true

describe AmaNotificationEfolderSyncJob, :postgres, type: :job do
  include ActiveJob::TestHelper
  let!(:current_user) { create(:user, roles: ["System Admin"]) }
  let!(:appeals) { create_list(:appeal, 10, :active) }
  let!(:job) { AmaNotificationEfolderSyncJob.new }

  first_run_vbms_document_appeal_indexes = []
  BATCH_LIMIT_SIZE = 5

  describe "perform" do
    before { Seeds::NotificationEvents.new.seed! }

    let!(:today) { Time.now.utc.iso8601 }
    let!(:notifications) do
      appeals.each_with_index do |appeal, index|
        next if [3, 7].include? index

        create(:notification,
               appeals_id: appeal.uuid,
               appeals_type: "Appeal",
               event_date: today,
               event_type: "Appeal docketed",
               notification_type: "Email",
               notified_at: Time.zone.now - (10 - index).minutes,
               email_notification_status: "delivered")
      end
    end

    let!(:make_appeals_outcoded) do
      RootTask.find_by(appeal_id: appeals[5].id).update!(status: "completed", closed_at: 3.days.ago)
      RootTask.find_by(appeal_id: appeals[6].id).update!(status: "completed", closed_at: today)
    end

    let!(:first_run_outcoded_appeals) { [appeals[6]] }
    let!(:first_run_never_synced_appeals) { appeals.first(3) + [appeals[4]] + appeals.last(2) }

    before(:all) { AmaNotificationEfolderSyncJob::BATCH_LIMIT = BATCH_LIMIT_SIZE }

    context "first run" do
      before { VbmsUploadedDocument.delete_all }

      it "get all ama appeals that have been recently outcoded" do
        expect(job.send(:appeals_recently_outcoded)).to match_array(first_run_outcoded_appeals)
      end

      it "get all ama appeals that have never been synced yet" do
        expect(job.send(:appeals_never_synced)).to match_array(first_run_never_synced_appeals)
      end

      it "get all ama appeals that must be resynced" do
        expect(job.send(:ready_for_resync)).to eq([])
      end

      it "running the perform" do
        perform_enqueued_jobs { AmaNotificationEfolderSyncJob.perform_later }

        first_run_vbms_document_appeal_indexes =
          VbmsUploadedDocument.first(5)
            .pluck(:appeal_id)
            .map { |appeal_id| find_appeal_index_by_id(appeal_id) }
            .compact

        expect(first_run_vbms_document_appeal_indexes.size).to eq BATCH_LIMIT_SIZE
      end
    end

    context "second run" do
      # Appeal IDs change between tests. Finds the appeals from the first job execution for this context.
      let(:first_run_vbms_document_appeal_ids) do
        first_run_vbms_document_appeal_indexes.map { |idx| appeals[idx].id }
      end

      # These appeals do not have notifications, or were outcoded too long ago.
      let(:will_not_sync_appeal_ids) { [appeals[3].id, appeals[5].id, appeals[7].id] }

      # There are no more appeals that have been outcoded within the last 24 hours
      let(:second_run_outcoded_appeals) { [] }

      # These appeals will be the ones that have not already been processed but should receive
      # notifications reports.
      let(:second_run_never_synced_appeals_ids) do
        appeals.map(&:id) - first_run_vbms_document_appeal_ids - will_not_sync_appeal_ids
      end

      # These appeals should be all that have had notification reports generated for them after two
      # runs with BATCH_LIMIT_SIZE number of appeals processed each time.
      let(:second_run_vbms_document_appeal_ids) do
        first_run_vbms_document_appeal_ids +
          [appeals[4].id] -
          will_not_sync_appeal_ids +
          second_run_never_synced_appeals_ids
      end

      before do
        perform_enqueued_jobs { AmaNotificationEfolderSyncJob.perform_later }

        RootTask.find_by(appeal_id: appeals[6].id).update!(closed_at: 25.hours.ago)
      end

      it "get all ama appeals that have been recently outcoded" do
        expect(job.send(:appeals_recently_outcoded)).to match_array(second_run_outcoded_appeals)
      end

      it "get all ama appeals that have never been synced yet" do
        create(:notification,
               appeals_id: appeals[4].uuid,
               appeals_type: "Appeal",
               event_date: today,
               event_type: "Appeal docketed",
               notification_type: "Email",
               notified_at: 3.minutes.ago,
               email_notification_status: "delivered")

        expect(
          job.send(:appeals_never_synced).map(&:id)
        ).to match_array(second_run_never_synced_appeals_ids)
      end

      it "get all ama appeals that must be resynced" do
        create(:notification,
               appeals_id: appeals[4].uuid,
               appeals_type: "Appeal",
               event_date: today,
               event_type: "Appeal docketed",
               notification_type: "Email",
               notified_at: 2.minutes.ago,
               email_notification_status: "delivered")

        expect(job.send(:ready_for_resync)).to eq([appeals[4]])
      end

      it "ignore appeals that need to be resynced if latest notification status is 'Failure Due to Deceased" do
        create(:notification,
               appeals_id: appeals[4].uuid,
               appeals_type: "Appeal",
               event_date: today,
               event_type: "Appeal docketed",
               notification_type: "Email",
               notified_at: 1.minute.ago,
               email_notification_status: "Failure Due to Deceased")

        expect(job.send(:ready_for_resync)).to eq([])
      end

      it "running the perform" do
        create(:notification,
               appeals_id: appeals[4].uuid,
               appeals_type: "Appeal",
               event_date: today,
               event_type: "Appeal docketed",
               notification_type: "Email",
               notified_at: Time.zone.now,
               email_notification_status: "delivered")

        perform_enqueued_jobs { AmaNotificationEfolderSyncJob.perform_later }

        expect(
          VbmsUploadedDocument
            .where(document_type: "BVA Case Notifications")
            .order(:id)
            .pluck(:appeal_id)
        ).to match_array(second_run_vbms_document_appeal_ids)
      end
    end

    def find_appeal_index_by_id(id)
      appeal_ids = appeals.map(&:id)

      appeal_ids.find_index(id)
    end
  end
end
