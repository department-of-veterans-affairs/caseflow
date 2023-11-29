# frozen_string_literal: true

describe SendNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:notification) do
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: "Hearing scheduled",
           event_date: Time.zone.today,
           notification_type: "Email")
  end
  let(:legacy_appeal_notification) do
    create(:notification,
           appeals_id: "123456",
           appeals_type: "LegacyAppeal",
           event_type: "Appeal docketed",
           event_date: Time.zone.today,
           notification_type: "SMS")
  end
  let(:appeal) do
    create(:appeal,
           docket_type: "Appeal",
           uuid: "5d70058f-8641-4155-bae8-5af4b61b1576",
           homelessness: false,
           veteran_file_number: "123456789")
  end
  let!(:no_name_appeal) do
    create(:appeal,
           docket_type: "Appeal",
           homelessness: false,
           veteran: no_name_veteran)
  end
  let(:no_name_veteran) do
    create(:veteran,
           file_number: "246813579",
           first_name: nil,
           middle_name: nil,
           last_name: nil)
  end
  # rubocop:disable Style/BlockDelimiters
  let(:good_template_name) { "Appeal docketed" }
  let(:error_template_name) { "No Participant Id Found" }
  let(:success_status) { "Success" }
  let(:error_status) { "No participant_id" }
  let(:success_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
      appeal_type: "Appeal"
    }
  }
  let(:success_legacy_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: "123456",
      appeal_type: "LegacyAppeal"
    }
  }
  let(:no_name_message_attributes) {
    {
      participant_id: "246813579",
      status: success_status,
      appeal_id: no_name_appeal.uuid,
      appeal_type: "Appeal"
    }
  }
  let(:error_message_attributes) {
    {
      participant_id: nil,
      status: error_status,
      appeal_id: "5d70058f-8641-4155-bae8-5af4b61b1578",
      appeal_type: "Appeal"
    }
  }
  let(:fail_create_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
      appeal_type: nil
    }
  }
  let(:good_message) { VANotifySendMessageTemplate.new(success_message_attributes, good_template_name) }
  let(:legacy_message) { VANotifySendMessageTemplate.new(success_legacy_message_attributes, good_template_name) }
  let(:no_name_message) { VANotifySendMessageTemplate.new(no_name_message_attributes, good_template_name) }
  let(:bad_message) { VANotifySendMessageTemplate.new(error_message_attributes, error_template_name) }
  let(:fail_create_message) { VANotifySendMessageTemplate.new(fail_create_message_attributes, error_template_name) }
  let(:quarterly_message) { VANotifySendMessageTemplate.new(success_message_attributes, "Quarterly Notification") }
  let(:participant_id) { success_message_attributes[:participant_id] }
  let(:no_name_participant_id) { no_name_message_attributes[:participant_id] }
  let(:bad_participant_id) { "123" }
  let(:appeal_id) { success_message_attributes[:appeal_id] }
  let(:email_template_id) { "d78cdba9-f02f-43dd-ab89-3ce42cc88078" }
  let(:bad_response) {
    HTTPI::Response.new(
      400,
      {},
      OpenStruct.new(
        "error": "BadRequestError",
        "message": "participant id is not valid"
      )
    )
  }
  let(:good_response) {
    HTTPI::Response.new(
      200,
      {},
      OpenStruct.new(
        "id": SecureRandom.uuid,
        "reference": "string",
        "uri": "string",
        "template": {
          "id" => email_template_id,
          "version" => 0,
          "uri" => "string"
        },
        "scheduled_for": "string",
        "content": {
          "body" => "string",
          "subject" => "string"
        }
      )
    )
  }
  let(:notification_events_id) { "VSO IHP complete" }
  let(:notification_type) { "VSO IHP complete" }
  let(:queue_name) { "caseflow_test_send_notifications" }
  # rubocop:enable Style/BlockDelimiters

  before do
    Seeds::NotificationEvents.new.seed!
  end

  after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    expect(SendNotificationJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    subject(:job) { SendNotificationJob.perform_later(good_message.to_json) }
    describe "send message to queue" do
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "processes message" do
        appeal
        perform_enqueued_jobs do
          result = SendNotificationJob.perform_later(good_message.to_json)
          expect(result.arguments[0]).to eq(good_message.to_json)
        end
      end

      it "logs error when message is nil" do
        expect(Rails.logger).to receive(:error).with(/There was no message passed/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(nil)
        end
      end

      it "logs error when appeals_id, appeals_type, or event_type is nil" do
        expect(Rails.logger).to receive(:error).with(/appeals_id or appeal_type or event_type/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(fail_create_message.to_json)
        end
      end

      it "logs error when audit record is nil" do
        allow_any_instance_of(SendNotificationJob).to receive(:create_notification_audit_record).and_return(nil)
        expect(Rails.logger).to receive(:error).with(/Audit record was unable to be found or created/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(good_message.to_json)
        end
      end

      it "sends to VA Notify when no errors are present" do
        expect(Rails.logger).not_to receive(:error)
        expect { SendNotificationJob.perform_now(good_message.to_json).to receive(:send_to_va_notify) }
      end

      it "saves to db but does not notify when status is not Success" do
        expect(Rails.logger).not_to receive(:error)
        expect { SendNotificationJob.perform_now(good_message.to_json).not_to receive(:send_to_va_notify) }
      end
    end

    describe "handling errors" do
      it "retries on internal server error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "retries on not found error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyNotFoundError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "retries on rate limit error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyRateLimitError)
        expect(Rails.logger).to receive(:error).with(/Retrying/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "discards on unauthorized error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyUnauthorizedError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "discards on forbidden error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyForbiddenError)
        expect(Rails.logger).to receive(:warn).with(/Discarding/)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(bad_message.to_json)
        end
      end

      it "retries on retriable error" do
        allow_any_instance_of(SendNotificationJob)
          .to receive(:perform)
          .and_raise(Caseflow::Error::VANotifyInternalServerError)
        expect_any_instance_of(SendNotificationJob).to receive(:retry_job)
        perform_enqueued_jobs do
          SendNotificationJob.perform_later(good_message.to_json)
        end
      end
    end
  end

  describe "#create_notification_audit_record" do
    it "makes a new notification object" do
      expect(Notification).to receive(:new)
      SendNotificationJob.perform_now(good_message.to_json)
    end
  end

  before do
    appeal
  end

  context "va_notify FeatureToggles" do
    describe "email" do
      it "is expected to send when the feature toggle is on" do
        FeatureToggle.enable!(:va_notify_email)
        expect(VANotifyService).to receive(:send_email_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
      it "updates the notification_content field with content" do
        FeatureToggle.enable!(:va_notify_email)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.notification_content).not_to eq(nil)
      end
      it "updates the email_notification_content field with content" do
        FeatureToggle.enable!(:va_notify_email)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.email_notification_content).not_to eq(nil)
      end
      it "updates the notification_audit_record with email_notification_external_id" do
        FeatureToggle.enable!(:va_notify_email)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.email_notification_external_id).not_to eq(nil)
      end
      it "is expected to not send when the feature toggle is off" do
        FeatureToggle.disable!(:va_notify_email)
        expect(VANotifyService).not_to receive(:send_email_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
    end

    describe "sms" do
      it "is expected to send when the feature toggle is on" do
        FeatureToggle.enable!(:va_notify_sms)
        expect(VANotifyService).to receive(:send_sms_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
      it "updates the sms_notification_content field with content" do
        FeatureToggle.enable!(:va_notify_sms)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.sms_notification_content).not_to eq(nil)
      end
      it "updates the notification_audit_record with sms_notification_external_id" do
        FeatureToggle.enable!(:va_notify_sms)
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.sms_notification_external_id).not_to eq(nil)
      end
      it "is expected to not send when the feature toggle is off" do
        FeatureToggle.disable!(:va_notify_sms)
        expect(VANotifyService).not_to receive(:send_sms_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
    end
  end

  context "appeal first name not found" do
    let(:notification_event) { NotificationEvent.find_by(event_type: "Appeal docketed") }

    describe "email" do
      before { FeatureToggle.enable!(:va_notify_email) }
      after { FeatureToggle.disable!(:va_notify_email) }

      it "is expected to send a generic saluation instead of a name" do
        expect(VANotifyService).to receive(:send_email_notifications).with(
          no_name_participant_id,
          "",
          notification_event.email_template_id,
          "Appellant",
          no_name_appeal.docket_number,
          ""
        )

        SendNotificationJob.perform_now(no_name_message.to_json)
      end
    end

    describe "sms" do
      before { FeatureToggle.enable!(:va_notify_sms) }
      after { FeatureToggle.disable!(:va_notify_sms) }

      it "is expected to send a generic saluation instead of a name" do
        expect(VANotifyService).to receive(:send_sms_notifications).with(
          no_name_participant_id,
          "",
          notification_event.sms_template_id,
          "Appellant",
          no_name_appeal.docket_number,
          ""
        )

        SendNotificationJob.perform_now(no_name_message.to_json)
      end
    end
  end

  context "on retry" do
    describe "notification object" do
      it "does not create multiple notification objects" do
        FeatureToggle.enable!(:va_notify_email)
        job = SendNotificationJob.new(good_message.to_json)
        job.instance_variable_set(:@notification_audit_record, notification)
        expect(Notification).not_to receive(:create)
        job.perform_now
      end
    end
  end

  context "feature flags for setting notification type" do
    it "notification type should be email if only email flag is on" do
      job = SendNotificationJob.new(good_message.to_json)
      job.instance_variable_set(:@va_notify_email, true)
      record = job.send(:create_notification_audit_record,
                        notification.appeals_id,
                        notification.appeals_type,
                        notification.event_type,
                        "123456789")
      expect(record.notification_type).to eq("Email")
    end

    it "notification type should be sms if only sms flag is on" do
      job = SendNotificationJob.new(good_message.to_json)
      job.instance_variable_set(:@va_notify_sms, true)
      record = job.send(:create_notification_audit_record,
                        notification.appeals_id,
                        notification.appeals_type,
                        notification.event_type,
                        "123456789")
      expect(record.notification_type).to eq("SMS")
    end

    it "notification type should be email and sms if both of those flags are on" do
      job = SendNotificationJob.new(good_message.to_json)
      job.instance_variable_set(:@va_notify_email, true)
      job.instance_variable_set(:@va_notify_sms, true)
      record = job.send(:create_notification_audit_record,
                        notification.appeals_id,
                        notification.appeals_type,
                        notification.event_type,
                        "123456789")
      expect(record.notification_type).to eq("Email and SMS")
    end
  end

  context "feature flags for sending legacy notifications" do
    it "should only send notifications when feature flag is turned on" do
      FeatureToggle.enable!(:appeal_docketed_notification)
      job = SendNotificationJob.new(legacy_message.to_json)
      job.instance_variable_set(:@notification_audit_record, notification)
      expect(job).to receive(:send_to_va_notify)
      job.perform_now
    end

    it "should not send notifications when feature flag is turned off" do
      FeatureToggle.disable!(:appeal_docketed_notification)
      job = SendNotificationJob.new(legacy_message.to_json)
      job.instance_variable_set(:@notification_audit_record, notification)
      expect(job).not_to receive(:send_to_va_notify)
      job.perform_now
    end
  end

  context "feature flag testing for creating legacy appeal notification records" do
    it "should only create an instance of a notification before saving if a notification was found" do
      FeatureToggle.enable!(:appeal_docketed_event)
      job = SendNotificationJob.new(legacy_message.to_json)
      expect(Notification).to receive(:new)
      job.perform_now
    end

    it "should return the notification record if one is found and not try to create one" do
      legacy_appeal_notification
      FeatureToggle.enable!(:appeal_docketed_event)
      FeatureToggle.enable!(:va_notify_sms)
      job = SendNotificationJob.new(legacy_message.to_json)
      job.instance_variable_set(:@va_notify_sms, true)
      expect(Notification).not_to receive(:new)
      job.perform_now
    end
  end

  context "feature flag for quarterly notifications" do
    it "should send an sms for quarterly notifications when the flag is on" do
      FeatureToggle.enable!(:va_notify_quarterly_sms)
      expect(VANotifyService).to receive(:send_sms_notifications)
      SendNotificationJob.new(quarterly_message.to_json).perform_now
    end

    it "should not send an sms for quarterly notifications when the flag is off" do
      FeatureToggle.disable!(:va_notify_quarterly_sms)
      expect(VANotifyService).not_to receive(:send_sms_notifications)
      SendNotificationJob.new(quarterly_message.to_json).perform_now
    end
  end

  context "no participant or claimant found" do
    it "the email status should be updated to say no participant id if that is the message" do
      FeatureToggle.enable!(:va_notify_email)
      SendNotificationJob.new(bad_message.to_json).perform_now
      expect(Notification.first.email_notification_status).to eq("No Participant Id Found")
    end

    it "the sms status should be updated to say no participant id if that is the message" do
      FeatureToggle.enable!(:va_notify_sms)
      SendNotificationJob.new(bad_message.to_json).perform_now
      expect(Notification.first.sms_notification_status).to eq("No Participant Id Found")
    end
  end
end
