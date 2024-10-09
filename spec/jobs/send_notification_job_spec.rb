# frozen_string_literal: true

describe SendNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  let(:notification) do
    create(:notification,
           appeals_id: "5d70058f-8641-4155-bae8-5af4b61b1576",
           appeals_type: "Appeal",
           event_type: Constants.EVENT_TYPE_FILTERS.hearing_scheduled,
           event_date: Time.zone.today,
           notification_type: "Email",
           notifiable: appeal)
  end
  let(:legacy_appeal_notification) do
    create(:notification,
           appeals_id: "123456",
           appeals_type: "LegacyAppeal",
           event_type: Constants.EVENT_TYPE_FILTERS.appeal_docketed,
           event_date: Time.zone.today,
           notification_type: "Email and SMS",
           notifiable: appeal)
  end
  let(:appeal) do
    create(:appeal,
           docket_type: "Appeal",
           uuid: "5d70058f-8641-4155-bae8-5af4b61b1576",
           homelessness: false,
           veteran_file_number: "123456789")
  end
  let(:legacy_appeal) { create(:legacy_appeal) }
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
  let(:good_template_name) { Constants.EVENT_TYPE_FILTERS.appeal_docketed }
  let(:error_template_name) { "No Participant Id Found" }
  let(:deceased_status) { "Failure Due to Deceased" }
  let(:success_status) { "Success" }
  let(:error_status) { "No participant_id" }
  let(:success_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: appeal.external_id,
      appeal_type: appeal.class.name
    }
  }
  let(:success_legacy_message_attributes) {
    {
      participant_id: "123456789",
      status: success_status,
      appeal_id: legacy_appeal.external_id,
      appeal_type: legacy_appeal.class.name
    }
  }
  let(:deceased_legacy_message_attributes) {
    {
      participant_id: "123456789",
      status: deceased_status,
      appeal_id: target_appeal.external_id,
      appeal_type: target_appeal.class.name
    }
  }
  let(:no_name_message_attributes) {
    {
      participant_id: "246813579",
      status: success_status,
      appeal_id: no_name_appeal.uuid,
      appeal_type: appeal.class.name
    }
  }
  let(:error_message_attributes) {
    {
      participant_id: nil,
      status: error_status,
      appeal_id: appeal.external_id,
      appeal_type: appeal.class.name
    }
  }
  let(:deceased_message_attributes) {
    {
      participant_id: "123456789",
      status: deceased_status,
      appeal_id: target_appeal.external_id,
      appeal_type: target_appeal.class.name
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
  let(:legacy_deceased_message) do
    AppellantNotification.create_payload(target_appeal, good_template_name).to_json
  end
  let(:no_name_message) { VANotifySendMessageTemplate.new(no_name_message_attributes, good_template_name) }
  let(:bad_message) { VANotifySendMessageTemplate.new(error_message_attributes, error_template_name) }
  let(:deceased_message) { VANotifySendMessageTemplate.new(deceased_message_attributes, good_template_name).to_json }
  let(:fail_create_message) { VANotifySendMessageTemplate.new(fail_create_message_attributes, error_template_name) }
  let(:quarterly_message) {
    VANotifySendMessageTemplate.new(success_message_attributes,
                                    Constants.EVENT_TYPE_FILTERS.quarterly_notification)
  }
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
  let(:notification_events_id) { Constants.EVENT_TYPE_FILTERS.vso_ihp_complete }
  let(:notification_type) { Constants.EVENT_TYPE_FILTERS.vso_ihp_complete }
  let(:queue_name) { "caseflow_test_send_notifications" }
  let(:appeal_to_notify_about) { create(:appeal, :with_deceased_veteran) }
  let(:cob_user) do
    create(:user).tap do |new_user|
      OrganizationsUser.make_user_admin(new_user, ClerkOfTheBoard.singleton)
    end
  end

  let(:substitution) { AppellantSubstitution.new(created_by_id: cob_user.id, source_appeal_id: appeal.id) }
  # rubocop:enable Style/BlockDelimiters

  before do
    Seeds::NotificationEvents.new.seed!
  end

  after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  context "#queue_name_suffix" do
    subject { described_class.queue_name_suffix }

    it "returns FIFO name" do
      is_expected.to eq :"send_notifications.fifo"
    end
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
        expect(Rails.logger).to receive(:send).with(:error, /Message argument of value nil supplied to job/)
        perform_enqueued_jobs do
          expect_any_instance_of(SendNotificationJob).to receive(:log_error) do |_recipient, error_received|
            expect(error_received.message).to eq "There was no message passed into the " \
               "SendNotificationJob.perform_later function. Exiting job."
          end

          SendNotificationJob.perform_later(nil)
        end
      end

      it "logs error when appeals_id, appeals_type, or event_type is nil" do
        expect(Rails.logger).to receive(:send).with(:error, /Nil message attribute\(s\): appeal_type/)
        perform_enqueued_jobs do
          expect_any_instance_of(SendNotificationJob).to receive(:log_error) do |_recipient, error_received|
            expect(error_received.message).to eq "appeals_id or appeal_type or event_type was nil " \
              "in the SendNotificationJob. Exiting job."
          end

          SendNotificationJob.perform_later(fail_create_message.to_json)
        end
      end

      it "logs error when audit record is nil" do
        allow_any_instance_of(Notification).to receive(:nil?).and_return(true)

        expect(Rails.logger).to receive(:send)
          .with(:error, /Notification audit record was unable to be found or created/)
        perform_enqueued_jobs do
          expect_any_instance_of(SendNotificationJob).to receive(:log_error) do |_recipient, error_received|
            expect(error_received.message).to eq "Audit record was unable to be found or created " \
              "in SendNotificationJob. Exiting Job."
          end

          SendNotificationJob.perform_later(good_message.to_json)
        end
      end

      it "notification audit record is recreated when error is in DISCARD ERRORS" do
        expect(Rails.logger).to receive(:send).with(:error, /Message argument of value nil supplied to job/)
        perform_enqueued_jobs do
          expect_any_instance_of(SendNotificationJob).to receive(:log_error) do |_recipient|
            expect(SendNotificationJob).to receive(:find_or_create_notification_audit)
          end

          SendNotificationJob.perform_later(nil)
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

  describe "#create_notification" do
    it "makes a new notification object" do
      expect { SendNotificationJob.perform_now(good_message.to_json) }.to change(Notification, :count).by(1)
    end
  end

  before do
    appeal
  end

  context "va_notify FeatureToggles" do
    describe "email" do
      it "is expected to send when the feature toggle is on" do
        expect(VANotifyService).to receive(:send_email_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
      it "updates the notification_content field with content" do
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.notification_content).not_to eq(nil)
      end
      it "updates the email_notification_content field with content" do
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.email_notification_content).not_to eq(nil)
      end
      it "updates the notification_audit_record with email_notification_external_id" do
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.email_notification_external_id).not_to eq(nil)
      end
    end

    describe "sms" do
      before { FeatureToggle.enable!(:va_notify_sms) }
      after { FeatureToggle.disable!(:va_notify_sms) }
      it "is expected to send when the feature toggle is on" do
        expect(VANotifyService).to receive(:send_sms_notifications)
        SendNotificationJob.perform_now(good_message.to_json)
      end
      it "updates the sms_notification_content field with content" do
        SendNotificationJob.perform_now(good_message.to_json)
        expect(Notification.last.sms_notification_content).not_to eq(nil)
      end
      it "updates the notification_audit_record with sms_notification_external_id" do
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
    let(:notification_event) { NotificationEvent.find_by(event_type: Constants.EVENT_TYPE_FILTERS.appeal_docketed) }

    describe "email" do
      before { FeatureToggle.enable!(:va_notify_email) }
      after { FeatureToggle.disable!(:va_notify_email) }

      it "is expected to send a generic saluation instead of a name" do
        expect(VANotifyService).to receive(:send_email_notifications).with(hash_including(first_name: "Appellant"))
        SendNotificationJob.perform_now(no_name_message.to_json)
      end
    end

    describe "sms" do
      before { FeatureToggle.enable!(:va_notify_sms) }
      after { FeatureToggle.disable!(:va_notify_sms) }

      it "is expected to send a generic saluation instead of a name" do
        expect(VANotifyService).to receive(:send_sms_notifications).with(hash_including(first_name: "Appellant"))
        SendNotificationJob.perform_now(no_name_message.to_json)
      end
    end
  end

  context "on retry" do
    before { FeatureToggle.enable!(:va_notify_email) }
    after { FeatureToggle.disable!(:va_notify_email) }
    describe "notification object" do
      it "does not create multiple notification objects" do
        job = SendNotificationJob.new(good_message.to_json)
        allow(job).to receive(:find_or_create_notification_audit).and_return(notification)
        expect { job.perform_now }.not_to change(Notification, :count)
      end
    end
  end

  context "feature flags for setting notification type" do
    it "notification type should be email if only email flag is on" do
      FeatureToggle.enable!(:va_notify_email)
      job = SendNotificationJob.new(good_message.to_json)
      job.instance_variable_set(:@message, JSON.parse(job.arguments[0], object_class: OpenStruct))
      record = job.send(:find_or_create_notification_audit)
      expect(record.notification_type).to eq("Email")
      FeatureToggle.disable!(:va_notify_email)
    end

    it "notification type should be sms if only sms flag is on" do
      FeatureToggle.enable!(:va_notify_sms)
      job = SendNotificationJob.new(good_message.to_json)
      job.instance_variable_set(:@message, JSON.parse(job.arguments[0], object_class: OpenStruct))
      record = job.send(:find_or_create_notification_audit)
      expect(record.notification_type).to eq("Email and SMS")
      FeatureToggle.disable!(:va_notify_sms)
    end

    it "notification type should be email and sms if both of those flags are on" do
      FeatureToggle.enable!(:va_notify_email)
      FeatureToggle.enable!(:va_notify_sms)
      job = SendNotificationJob.new(good_message.to_json)
      job.instance_variable_set(:@message, JSON.parse(job.arguments[0], object_class: OpenStruct))
      record = job.send(:find_or_create_notification_audit)
      expect(record.notification_type).to eq("Email and SMS")
      FeatureToggle.disable!(:va_notify_email)
      FeatureToggle.disable!(:va_notify_sms)
    end
  end

  context "feature flag testing for creating legacy appeal notification records" do
    let(:legacy_appeal) { create(:legacy_appeal) }
    let!(:case) { create(:case, bfkey: legacy_appeal.vacols_id) }

    it "creates an instance of a notification" do
      FeatureToggle.enable!(:appeal_docketed_event)
      job = SendNotificationJob.new(legacy_message.to_json)
      allow(job).to receive(:find_appeal_by_external_id).and_return(legacy_appeal)
      expect(Notification).to receive(:create)
      job.perform_now
      FeatureToggle.disable!(:appeal_docketed_event)
    end
  end

  context "feature flag for quarterly notifications" do
    before do
      FeatureToggle.enable!(:va_notify_quarterly_sms)
    end

    after do
      FeatureToggle.disable!(:va_notify_quarterly_sms)
    end

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
    before do
      FeatureToggle.enable!(:va_notify_email)
      FeatureToggle.enable!(:va_notify_sms)
    end

    after do
      FeatureToggle.disable!(:va_notify_email)
      FeatureToggle.disable!(:va_notify_sms)
    end
    it "the email status should be updated to say no participant id if that is the message" do
      SendNotificationJob.new(bad_message.to_json).perform_now
      expect(Notification.first.email_notification_status).to eq("No Participant Id Found")
    end

    it "the sms status should be updated to say no participant id if that is the message" do
      SendNotificationJob.new(bad_message.to_json).perform_now
      expect(Notification.first.sms_notification_status).to eq("No Participant Id Found")
    end
  end

  context "Deceased veteran checks" do
    before do
      FeatureToggle.enable!(:va_notify_email)
      FeatureToggle.enable!(:va_notify_sms)
      FeatureToggle.enable!(:appeal_docketed_notification)
    end
    after do
      FeatureToggle.disable!(:va_notify_email)
      FeatureToggle.disable!(:va_notify_sms)
      FeatureToggle.disable!(:appeal_docketed_notification)
    end

    context "Appeal is the subject of the notification" do
      let!(:target_appeal) { create(:appeal, :with_deceased_veteran) }

      it "The veteran being the claimant and is alive" do
        expect(VANotifyService).to receive(:send_email_notifications)
        expect(VANotifyService).to receive(:send_sms_notifications)

        SendNotificationJob.new(good_message.to_json).perform_now

        expect(Notification.first.email_notification_status).to eq("Success")
      end

      it "The veteran being the claimant and is deceased" do
        expect(VANotifyService).to_not receive(:send_email_notifications)
        expect(VANotifyService).to_not receive(:send_sms_notifications)

        SendNotificationJob.perform_now(deceased_message)

        expect(Notification.first.email_notification_status).to eq("Failure Due to Deceased")
      end

      it "The veteran being deceased and there being an AppellantSubstitution on the appeal to swap the claimant" do
        substitution
        expect(VANotifyService).to_not receive(:send_email_notifications)
        expect(VANotifyService).to_not receive(:send_sms_notifications)

        SendNotificationJob.new(deceased_message).perform_now

        expect(Notification.first.email_notification_status).to eq("Failure Due to Deceased")
      end
    end

    context "Legacy Appeal is the subject of the notification" do
      let(:target_appeal)  do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(:case_with_form_9)
        )
      end

      it "The veteran being the claimant and is alive" do
        job = SendNotificationJob.new(legacy_message.to_json)
        job.instance_variable_set(:@notification_audit, notification)
        allow(job).to receive(:find_appeal_by_external_id).and_return(target_appeal)
        expect(job).to receive(:send_to_va_notify)

        job.perform_now

        expect(Notification.last.email_notification_status).to eq("Success")
      end

      it "The veteran being the claimant and is deceased" do
        target_appeal.veteran.update!(date_of_death: 2.weeks.ago)

        job = SendNotificationJob.new(legacy_deceased_message)
        job.instance_variable_set(:@notification_audit, notification)
        allow(job).to receive(:find_appeal_by_external_id).and_return(target_appeal)
        expect(job).to_not receive(:send_to_va_notify)

        job.perform_now

        expect(Notification.last.email_notification_status).to eq("Failure Due to Deceased")
      end
    end
  end
end
