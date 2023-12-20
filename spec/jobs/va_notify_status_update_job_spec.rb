# frozen_string_literal: true

describe VANotifyStatusUpdateJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:notifications_email_only) do
    FactoryBot.create_list :notification_email_only, 10
  end
  let(:notifications_sms_only) do
    FactoryBot.create_list :notification_sms_only, 10
  end
  let(:notifications_email_and_sms) do
    FactoryBot.create_list :notification_email_and_sms, 10
  end
  let(:email_only) do
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email",
           email_notification_status: "Success")
  end
  let(:sms_only) do
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "SMS",
           sms_notification_status: "Success")
  end
  let(:email_and_sms) do
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email and SMS",
           email_notification_status: "Success",
           sms_notification_status: "Success")
  end
  let(:notification_collection) do
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email",
           email_notification_external_id: "0",
           sms_notification_external_id: nil,
           email_notification_status: "Success",
           created_at: Time.zone.now)
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "SMS",
           email_notification_external_id: nil,
           sms_notification_external_id: "0",
           sms_notification_status: "temporary-failure",
           created_at: Time.zone.now)
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "SMS",
           email_notification_external_id: nil,
           sms_notification_external_id: "1",
           sms_notification_status: "created",
           created_at: Time.zone.now)
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email",
           email_notification_external_id: "1",
           sms_notification_external_id: nil,
           email_notification_status: "technical-failure",
           created_at: Time.zone.now)
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email and SMS",
           email_notification_external_id: "2",
           sms_notification_external_id: "2",
           email_notification_status: "temporary-failure",
           sms_notification_status: "temporary-failure",
           created_at: Time.zone.now - 5.days)
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email and SMS",
           email_notification_external_id: "3",
           sms_notification_external_id: "3",
           email_notification_status: "delivered",
           sms_notification_status: "delivered",
           created_at: Time.zone.now - 5.days)
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1577",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email and SMS",
           email_notification_external_id: "4",
           sms_notification_external_id: "4",
           email_notification_status: "delivered",
           sms_notification_status: "delivered",
           created_at: Time.zone.now - 5.days)
  end

  let(:collect) { Notification.where(id: [1, 2, 3, 4, 5]) }

  let(:queue_name) { "caseflow_test_low_priority" }

  before do
    Seeds::NotificationEvents.new.seed!
  end

  after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(VANotifyStatusUpdateJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { VANotifyStatusUpdateJob.perform_later }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "processes message" do
        perform_enqueued_jobs do
          result = VANotifyStatusUpdateJob.perform_later
          expect(result.arguments[0]).to eq(nil)
        end
      end

      it "sends to VA Notify when no errors are present" do
        expect(Rails.logger).not_to receive(:error)
        expect { VANotifyStatusUpdateJob.perform_now.to receive(:send_to_va_notify) }
      end

      it "defaults to 650 for the query limit if environment variable not found or invalid" do
        stub_const("VANotifyStatusUpdateJob::QUERY_LIMIT", nil)
        expect(Rails.logger).to receive(:info)
          .with("VANotifyStatusJob can not read the VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT environment variable.\
        Defaulting to 650.")
        VANotifyStatusUpdateJob.perform_now
      end

      it "logs out an error to Raven when email type that is not Email or SMS is found" do
        external_id = SecureRandom.uuid
        email_only.update!(email_notification_external_id: external_id)
        job_instance = VANotifyStatusUpdateJob.new
        external_id = SecureRandom.uuid
        result = job_instance.send(:get_current_status, external_id, "None")
        expect(result).to eq(false)
      end
    end

    describe "feature flags" do
      describe "Email" do
        it "updates the Notification when successful" do
          email_only.email_notification_external_id = SecureRandom.uuid
          allow(job).to receive(:notifications_not_processed).and_return([email_only])
          job.perform_now
          expect(email_only.email_notification_status).to eq("created")
        end
        it "logs when external id is not present" do
          allow(job).to receive(:notifications_not_processed).and_return([email_only])
          job.perform_now
          expect(email_only.email_notification_status).to eq("No External Id")
        end
      end

      describe "SMS" do
        it "updates the Notification when successful" do
          sms_only.sms_notification_external_id = SecureRandom.uuid
          allow(job).to receive(:notifications_not_processed).and_return([sms_only])
          job.perform_now
          expect(sms_only.sms_notification_status).to eq("created")
        end
        it "logs when external id is not present" do
          allow(job).to receive(:notifications_not_processed).and_return([sms_only])
          job.perform_now
          expect(sms_only.sms_notification_status).to eq("No External Id")
        end
      end

      describe "Email and SMS" do
        it "updates the Notification when successful" do
          email_and_sms.sms_notification_external_id = SecureRandom.uuid
          email_and_sms.email_notification_external_id = SecureRandom.uuid
          allow(job).to receive(:notifications_not_processed).and_return([email_and_sms])
          job.perform_now
          expect(email_and_sms.sms_notification_status && email_and_sms.email_notification_status).to eq("created")
        end
        it "logs when external id is not present" do
          allow(job).to receive(:notifications_not_processed).and_return([email_and_sms])
          job.perform_now
          expect(email_and_sms.sms_notification_status &&
            email_and_sms.email_notification_status).to eq("No External Id")
        end

        it "updates the email and sms notification status if an external id is found" do
          email_and_sms.update!(sms_notification_external_id: SecureRandom.uuid,
                                email_notification_external_id: SecureRandom.uuid)
          job.perform_now
          notification = Notification.first
          expect(notification.email_notification_status && notification.sms_notification_status).to eq("created")
        end
      end
    end
  end

  context "#get_current_status" do
    subject(:job) { VANotifyStatusUpdateJob.perform_later }
    it "handles VA Notify errors" do
      email_and_sms.sms_notification_external_id = SecureRandom.uuid
      email_and_sms.email_notification_external_id = SecureRandom.uuid
      allow(job).to receive(:notifications_not_processed).and_return([email_and_sms])
      allow(VANotifyService).to receive(:get_status).and_raise(Caseflow::Error::VANotifyNotFoundError)
      expect(job).to receive(:log_error).with(/VA Notify API returned error/).twice
      job.perform_now
    end
  end

  context "#notifications_not_processed" do
    subject(:job) { VANotifyStatusUpdateJob.perform_later }
    it "queries the notification table using activerecord" do
      allow(job).to receive(:find_notifications_not_processed).and_return([])
      expect(job.send(:find_notifications_not_processed))
      job.perform_now
    end
  end

  context "#find_notif_not_processed" do
    subject(:job) { VANotifyStatusUpdateJob.perform_later }
    it "returns a collection of notifications from the DB that hold the qualifying statuses" do
      notification_collection
      expect(job.send(:find_notifications_not_processed)).not_to include(Notification.where(id: [6, 7]))
    end
  end

  context "#default_to_650" do
    before do
      VANotifyStatusUpdateJob::QUERY_LIMIT = nil
    end

    subject(:job) { VANotifyStatusUpdateJob.perform_later }
    it "defaults to 650" do
      expect(Rails.logger).to receive(:info).with(
        "VANotifyStatusJob can not read the VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT environment variable.\
        Defaulting to 650."
      )
      job.perform
    end
  end
end
