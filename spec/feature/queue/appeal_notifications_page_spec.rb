# frozen_string_literal: true

require "spec_helper"

RSpec.feature "Notifications View" do
  let(:user_roles) { ["System Admin"] }
  before do
    User.authenticate!(roles: user_roles)
    Seeds::NotificationEvents.new.seed!
  end

  context "ama appeal" do
    let(:appeal) do
      create(:appeal)
    end
    let(:ama_notification) do
      create(:notification,
             appeals_id: appeal.uuid,
             appeals_type: "Appeal",
             event_date: Time.zone.today,
             event_type: "Appeal docketed",
             notification_type: "Email",
             notified_at: Time.zone.today,
             email_notification_status: "delivered")
    end
    let(:multiple_ama_notifications) do
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 8.days.ago,
                            event_type: "Appeal docketed", notification_type: "Email and SMS",
                            recipient_email: "example@example.com",recipient_phone_number: "555-555-5555",
                            email_notification_status: "delivered", sms_notification_status: "delivered",
                            notification_content: "Your appeal at the Board of Veteran's Appeals has been docketed. "\
                            "We must work cases in the order your VA Form 9 substantive appeal (for Legacy) or VA "\
                            "Form 10182 (for AMA) was received. We will update you with any progress. If you have "\
                            "any questions please reach out to your Veterans Service Organization or representative "\
                            "or log onto VA.gov for additional information.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 7.days.ago,
                            event_type: "Hearing scheduled", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
                            notification_content: "Your hearing has been scheduled with a Veterans Law Judge at the "\
                            "Board of Veterans' Appeals. You will be notified of the details in writing shortly.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 6.days.ago,
                            event_type: "Privacy Act request pending", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative filed a Privacy Act request. The Board "\
                            "placed your appeal on hold until this request is satisfied.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 5.days.ago,
                            event_type: "Privacy Act request complete", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
                            notification_content: "The Privacy Act request has been satisfied and the Board will "\
                            "continue processing your appeal at this time. The Board must work cases in docket order "\
                            "(the order received) If you have any questions please reach out to your Veterans Service "\
                            "Organization or representative, if you have one, or log onto VA.gov for additional "\
                            "information")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 4.days.ago,
                            event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative have requested to withdraw your hearing "\
                            "request. The Board will continue processing your appeal, but it must work cases in "\
                            "docket order (the order received). For more information please reach out to your "\
                            "Veterans Service Organization or representative, if you have one, or contact the "\
                            "hearing coordinator for your region. For a list of hearing coordinators by region "\
                            "with contact information, please visit https://www.bva.va.gov.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 3.days.ago,
                            event_type: "VSO IHP pending", notification_type: "Email and SMS", recipient_email: nil,
                            recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "You filed an appeal with the Board of Veterans' Appeals. Your case "\
                            "has been assigned to your Veterans Service Organization to provide written argument. "\
                            "Once the argument has been received, the Board of Veterans' Appeals will resume "\
                            "processing of your appeal.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 2.days.ago,
                            event_type: "VSO IHP complete", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "The Board of Veterans' Appeals received the written argument from "\
                            "your Veterans Service Organization. The Board will continue processing your appeal, but "\
                            "it must work cases in docket order (the order received). If you have any questions "\
                            "please reach out to your Veterans Service Organization or log onto VA.gov for additional "\
                            "information.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: 1.day.ago,
                            event_type: "Appeal decision mailed (Non-contested claims)",
                            notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil,
                            email_notification_status: "Success", sms_notification_status: "permanent-failure",
                            notification_content: "The Board of Veterans' Appeals issued a decision on your appeal "\
                            "that will be sent to you and to your representative, if you have one, shortly.")
    end

    scenario "admin visits notifications page for ama appeal" do
      multiple_ama_notifications
      visit "queue/appeals/#{appeal.uuid}"
      click_link("View notifications sent to appellant")
      current_path = "/queue/appeals/#{appeal.uuid}/notifications"
      page.switch_to_window(page.windows.last)
      expect(page).to have_current_path(current_path)
    end
  end
end
