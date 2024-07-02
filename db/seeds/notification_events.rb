# frozen_string_literal: true

# create notification-events seeds

module Seeds
  class NotificationEvents < Base
    def seed!
      create_notification_events
    end

    private

    def create_notification_events
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.quarterly_notification, email_template_id: "d9cf3926-d6b7-4ec7-ba06-a430741db68c", sms_template_id: "44ac639e-e90b-4423-8d7b-acfa8e5131d8")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.appeal_docketed, email_template_id: "ae2f0d17-247f-47ee-8f1a-b83a71e0f050", sms_template_id: "9953f7e8-80cb-4fe4-aaef-0309410c84e3")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.appeal_decision_mailed_non_contested_claims, email_template_id: "8124f1e1-975b-41f5-ad07-af078f783106", sms_template_id: "78b50f00-6707-464b-b3f9-c87b3f8ed790")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.appeal_decision_mailed_contested_claims, email_template_id: "dc4a0400-ee8f-4486-86d8-3b25ec7a43f3", sms_template_id: "ef418229-0c50-4fb1-8a3a-e134acc57bfc")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.hearing_scheduled, email_template_id: "27bf814b-f065-4fc8-89af-ae1292db894e", sms_template_id: "c2798da3-4c7a-43ed-bc16-599329eaf7cc")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.withdrawal_of_hearing, email_template_id: "14b0022f-0431-485b-a188-15f104766ef4", sms_template_id: "ec310973-b013-4b71-ac12-2ac86fb5738a")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.postponement_of_hearing, email_template_id: "e36fe052-258f-42aa-8b3e-a9aca1cd1c2e", sms_template_id: "27f3aa08-91e2-4e77-9636-5f6cb6bc7574")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.privacy_act_request_pending, email_template_id: "079ad556-ed04-4491-8661-19cd8b1c537d", sms_template_id: "69047f23-b161-441e-a155-0aeab62a886e")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.privacy_act_request_complete, email_template_id: "5b7a4450-2d9d-44ad-8691-cc195e3aa5e4", sms_template_id: "48ec08e3-bf86-4329-af2c-943415396699")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.vso_ihp_pending, email_template_id: "33f1f441-325e-4825-adb3-3bde3393d79d", sms_template_id: "3adcbf09-827d-4d02-af28-864ab2e56b6f")
      NotificationEvent.find_or_create_by(event_type: Constants.EVENT_TYPE_FILTERS.vso_ihp_complete, email_template_id: "33496907-3292-48cb-8543-949023941b4a", sms_template_id: "02bc8052-1a8c-4e55-bb33-66bb2b50ad67")
      # Following lines are fake uuids with no template
      NotificationEvent.find_or_create_by(event_type: "No Participant Id Found", email_template_id: "f54a9779-24b0-46a3-b2c1-494d42db0614", sms_template_id: "663c2b42-3381-46e4-9d48-f336d79901bc")
      NotificationEvent.find_or_create_by(event_type: "No Claimant Found", email_template_id: "ff871007-1f40-455d-beb3-5f2c71d065fc", sms_template_id: "364dd348-d577-44e8-82de-9fa000d6cd74")
    end
  end
end
