# frozen_string_literal: true

# create notification-events seeds

module Seeds
    class Notification < Base
      def seed!
        create_notifications
      end

      private

      def appeal_docketed_text
        return "Your appeal at the Board of Veterans' Appeals has been docketed. We must work cases in the order in your VA Form 9 substantive appeal (for Legacy) or VA Form 10182 (for AMA) was recieved. We will update you with any progress. If you have any questions please reach out to your Veterans Service Organization or representative or log onto VA.gov for additional information."
      end

      def hearing_scheduled_text
        return "Your hearing has been scheduled with a Veterans Law Judge at the Board of Veteran's Appeals. You will be notified of the details in writing shortly."
      end

      def privacy_act_complete_text
        return "The Privacy Act request has been satisfied and the Board will continue processing your appeal at this time. The Board must work cases in docket order (the order recieved). If you have any questions please reach out to your Veterans Service Organization or representative or log onto VA.gov for additional information"
      end

      def create_ama_notifications
        Notification.create(
            appeals_id: "dfa67dda-c6d3-481a-9a0f-cf91a498fb50",
            appeals_type: "Appeal",
            email_notification_status: "delivered",
            event_date: "2022-10-29",
            event_type: "Appeal docketed",
            notification_content: appeal_docketed_text,
            notification_type: "Email",
            notified_at: "2022-10-27",
            participant_id:"601520010",
            recipient_email: "test@caseflow.com",
            recipient_phone_number: "1234567890",
            email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
        )
        Notification.create(
            appeals_id: "2243bbef-5ef3-4371-87a6-7ed1b4b6ac3e",
            appeals_type: "Appeal",
            email_notification_status: "Success",
            event_date: "2022-10-28",
            event_type: "Appeal docketed",
            notification_content: privacy_act_complete_text,
            notification_type: "Email",
            notified_at: "2022-10-29",
            participant_id:"601520010",
            recipient_email: "",
            recipient_phone_number: "",
            email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
        )
        for i in 1..5 do
            Notification.create(
                appeals_id: "2243bbef-5ef3-4371-87a6-7ed1b4b6ac3e",
                appeals_type: "Appeal",
                email_notification_status: "delivered",
                event_date: "2022-10-27",
                event_type: "Hearing scheduled",
                notification_content: hearing_scheduled_text,
                notification_type: "Email",
                notified_at: "2022-10-29",
                participant_id:"601520010",
                recipient_email: "test@caseflow.com",
                recipient_phone_number: "",
                email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
            )
            Notification.create(
                appeals_id: "2243bbef-5ef3-4371-87a6-7ed1b4b6ac3e",
                appeals_type: "Appeal",
                email_notification_status: "delivered",
                event_date: "2022-10-27",
                event_type: "Appeal docketed",
                notification_content: appeal_docketed_text,
                notification_type: "Email",
                notified_at: "2022-10-29",
                participant_id:"601520010",
                recipient_email: "test@caseflow.com",
                recipient_phone_number: "",
                email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
            )
            Notification.create(
                appeals_id: "2243bbef-5ef3-4371-87a6-7ed1b4b6ac3e",
                appeals_type: "Appeal",
                email_notification_status: "delivered",
                event_date: "2022-11-01",
                event_type: "Privacy Act request complete",
                notification_content: privacy_act_complete_text,
                notification_type: "Email",
                notified_at: "2022-10-29",
                participant_id:"601520010",
                recipient_email: "test@caseflow.com",
                recipient_phone_number: "",
                email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
            )
        end
      end

      def create_legacy_notifications
        Notification.create(
            appeals_id: "738310343",
            appeals_type: "LegacyAppeal",
            email_notification_status: "delivered",
            event_date: "2022-10-29",
            event_type: "Appeal docketed",
            notification_content: appeal_docketed_text,
            notification_type: "Email",
            notified_at: "2022-10-27",
            participant_id:"601520010",
            recipient_email: "test@caseflow.com",
            recipient_phone_number: "1234567890",
            email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
        )
        Notification.create(
            appeals_id: "738310345",
            appeals_type: "LegacyAppeal",
            email_notification_status: "Success",
            event_date: "2022-10-28",
            event_type: "Appeal docketed",
            notification_content: privacy_act_complete_text,
            notification_type: "Email",
            notified_at: "2022-10-29",
            participant_id:"601520010",
            recipient_email: "",
            recipient_phone_number: "",
            email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
        )
        for i in 1..5 do
            Notification.create(
                appeals_id: "738310345",
                appeals_type: "LegacyAppeal",
                email_notification_status: "delivered",
                event_date: "2022-10-27",
                event_type: "Hearing scheduled",
                notification_content: hearing_scheduled_text,
                notification_type: "Email",
                notified_at: "2022-10-29",
                participant_id:"601520010",
                recipient_email: "test@caseflow.com",
                recipient_phone_number: "",
                email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
            )
            Notification.create(
                appeals_id: "738310345",
                appeals_type: "LegacyAppeal",
                email_notification_status: "delivered",
                event_date: "2022-10-27",
                event_type: "Appeal docketed",
                notification_content: appeal_docketed_text,
                notification_type: "Email",
                notified_at: "2022-10-29",
                participant_id:"601520010",
                recipient_email: "test@caseflow.com",
                recipient_phone_number: "",
                email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
            )
            Notification.create(
                appeals_id: "738310345",
                appeals_type: "LegacyAppeal",
                email_notification_status: "delivered",
                event_date: "2022-11-01",
                event_type: "Privacy Act request complete",
                notification_content: privacy_act_complete_text,
                notification_type: "Email",
                notified_at: "2022-10-29",
                participant_id:"601520010",
                recipient_email: "test@caseflow.com",
                recipient_phone_number: "",
                email_notification_external_id: "44495740-7ea2-4dc1-acc8-c1d47751cabd"
            )
        end
      end

      def create_notifications
        create_ama_notifications
        create_legacy_notifications
      end
    end
  end
