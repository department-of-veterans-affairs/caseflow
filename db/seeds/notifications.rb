# frozen_string_literal: true

# create notification-events seeds

module Seeds
  class Notifications < Base
    def seed!
      create_notifications
    end
  
    private
  
    def create_notifications
      # Multiple Notifications for Legacy Appeal 2226048
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered", sms_notification_status: "Delivered")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
        notification_type: "Email and SMS", recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Success",
        sms_notification_status: "permanent-failure")

      # Multiple Notifications for Legacy Appeal 2309289
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered", sms_notification_status: "Delivered")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
        notification_type: "Email and SMS", recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Success",
        sms_notification_status: "permanent-failure")

      # Multiple Notifications for Legacy Appeal 2362049
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered", sms_notification_status: "Delivered")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
        notification_type: "Email and SMS", recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Success",
        sms_notification_status: "permanent-failure")

      # Single Notification for Legacy Appeal 2591483
      Notification.create(appeals_id: "2591483", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
        
      # Single Notification for Legacy Appeal 2687879
      Notification.create(appeals_id: "2687879", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")

      # Single Notification for Legacy Appeal 2727431
      Notification.create(appeals_id: "2727431", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")

      # Multiple Notifications for AMA Appeal d31d7f91-91a0-46f8-b4bc-c57e139cee72
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered", sms_notification_status: "Delivered")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
          notification_type: "Email and SMS", recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Success",
          sms_notification_status: "permanent-failure")

      # Multiple Notifications for AMA Appeal 25c4857b-3cc5-4497-a066-25be73aa4b6b
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered", sms_notification_status: "Delivered")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
          notification_type: "Email and SMS", recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Success",
          sms_notification_status: "permanent-failure")

      # Multiple Notifications for AMA Appeal 7a060e04-1143-4e42-9ede-bdc42877f4f8
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered", sms_notification_status: "Delivered")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Delivered",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success",  sms_notification_status: "temporary-failure")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "Success", sms_notification_status: "Success")
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
          notification_type: "Email and SMS", recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Success",
          sms_notification_status: "permanent-failure")

      # Single Notification for AMA Appeal 952b6490-a10a-484b-a29b-31489e9a6e5a
      Notification.create(appeals_id: "952b6490-a10a-484b-a29b-31489e9a6e5a", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Delivered", sms_notification_status: "permanent-failure")

      # Single Notification for AMA Appeal fb3b029f-f07e-45bf-9277-809b44f7451a
      Notification.create(appeals_id: "fb3b029f-f07e-45bf-9277-809b44f7451a", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Delivered", sms_notification_status: "permanent-failure")

      # Single Notification for AMA Appeal 2b3afced-f698-4abe-84f9-6d44f26d20d4
      Notification.create(appeals_id: "2b3afced-f698-4abe-84f9-6d44f26d20d4", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "Delivered", sms_notification_status: "permanent-failure")
    end
  end
end