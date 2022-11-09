# frozen_string_literal: true

require "spec_helper"

RSpec.feature "Notifications View" do
  let(:user_roles) { ["System Admin"] }
  before do
    User.authenticate!(roles: user_roles)
    Seeds::NotificationEvents.new.seed!
    seed_ama_notifications
  end

  context "ama appeal" do
    let(:appeal) do
      create(:appeal)
    end
    let(:seed_ama_notifications) do
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-01",
                            event_type: "Appeal docketed", notification_type: "Email and SMS",
                            recipient_email: "example@example.com",recipient_phone_number: "555-555-5555",
                            email_notification_status: "delivered", sms_notification_status: "delivered",
                            notification_content: "Your appeal at the Board of Veteran's Appeals has been docketed. "\
                            "We must work cases in the order your VA Form 9 substantive appeal (for Legacy) or VA "\
                            "Form 10182 (for AMA) was received. We will update you with any progress. If you have "\
                            "any questions please reach out to your Veterans Service Organization or representative "\
                            "or log onto VA.gov for additional information.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-02",
                            event_type: "Hearing scheduled", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
                            notification_content: "Your hearing has been scheduled with a Veterans Law Judge at the "\
                            "Board of Veterans' Appeals. You will be notified of the details in writing shortly.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-03",
                            event_type: "Privacy Act request pending", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative filed a Privacy Act request. The Board "\
                            "placed your appeal on hold until this request is satisfied.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-04",
                            event_type: "Privacy Act request complete", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
                            notification_content: "The Privacy Act request has been satisfied and the Board will "\
                            "continue processing your appeal at this time. The Board must work cases in docket order "\
                            "(the order received) If you have any questions please reach out to your Veterans Service "\
                            "Organization or representative, if you have one, or log onto VA.gov for additional "\
                            "information")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-05",
                            event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative have requested to withdraw your hearing "\
                            "request. The Board will continue processing your appeal, but it must work cases in "\
                            "docket order (the order received). For more information please reach out to your "\
                            "Veterans Service Organization or representative, if you have one, or contact the "\
                            "hearing coordinator for your region. For a list of hearing coordinators by region "\
                            "with contact information, please visit https://www.bva.va.gov.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-06",
                            event_type: "VSO IHP pending", notification_type: "Email and SMS", recipient_email: nil,
                            recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "You filed an appeal with the Board of Veterans' Appeals. Your case "\
                            "has been assigned to your Veterans Service Organization to provide written argument. "\
                            "Once the argument has been received, the Board of Veterans' Appeals will resume "\
                            "processing of your appeal.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-07",
                            event_type: "VSO IHP complete", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "The Board of Veterans' Appeals received the written argument from "\
                            "your Veterans Service Organization. The Board will continue processing your appeal, but "\
                            "it must work cases in docket order (the order received). If you have any questions "\
                            "please reach out to your Veterans Service Organization or log onto VA.gov for additional "\
                            "information.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-08",
                            event_type: "Appeal decision mailed (Non-contested claims)",
                            notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil,
                            email_notification_status: "Success", sms_notification_status: "permanent-failure",
                            notification_content: "The Board of Veterans' Appeals issued a decision on your appeal "\
                            "that will be sent to you and to your representative, if you have one, shortly.")
    end

    scenario "visits notifications page for ama appeal" do
      visit "queue/appeals/#{appeal.uuid}"
      click_link("View notifications sent to appellant")
      page.switch_to_window(page.windows.last)
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/notifications")
    end

    scenario "sees correct event type in first row of table" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      cell = page.find("td", match: :first)
      expect(cell).to have_content("Appeal docketed")
    end

    scenario "sees correct notification date in first row of table" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      cell = page.all("td")[1]
      expect(cell).to have_content("11/01/2022")
    end

    scenario "sees correct notification type in first row of table" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      cell = page.all("td")[2]
      expect(cell).to have_content("Email")
    end

    scenario "sees correct recipient information in first row of table" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      cell = page.all("td")[3]
      expect(cell).to have_content("example@example.com")
    end

    scenario "sees correct status in first row of table" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      cell = page.all("td")[4]
      expect(cell).to have_content("Delivered")
    end

    scenario "table is filled with a full page of notifications" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 15)
    end

    scenario "can filter by event type" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      filter = page.find("rect", class: "unselected-filter-icon-border", match: :first)
      filter.click(x: 5, y: 5)
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Appeal docketed")
      filter_option.click(x: 5, y: 5)
      table = page.find("tbody")
      cells = table.all("td")
      expect(table).to have_selector("tr", count: 2)
      expect(cells[0]).to have_content("Appeal docketed")
      expect(cells[5]).to have_content("Appeal docketed")
    end

    scenario "can filter by notification type" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      filter = page.all("rect", class: "unselected-filter-icon-border")[1]
      filter.click(x: 5, y: 5)
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Email")
      filter_option.click(x: 5, y: 5)
      table = page.find("tbody")
      cells = table.all("td")
      expect(table).to have_selector("tr", count: 8)
      expect(cells[2]).to have_content("Email")
      expect(cells[37]).to have_content("Email")
    end

    scenario "can filter by recipient information" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      filter = page.all("rect", class: "unselected-filter-icon-border")[2]
      filter.click(x: 5, y: 5)
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Example@example.com")
      filter_option.click(x: 5, y: 5)
      table = page.find("tbody")
      cells = table.all("td")
      expect(table).to have_selector("tr", count: 4)
      expect(cells[3]).to have_content("example@example.com")
      expect(cells[18]).to have_content("example@example.com")
    end

    scenario "can filter by status" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      filter = page.all("rect", class: "unselected-filter-icon-border")[3]
      filter.click(x: 5, y: 5)
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Delivered")
      filter_option.click(x: 5, y: 5)
      table = page.find("tbody")
      cells = table.all("td")
      expect(table).to have_selector("tr", count: 5)
      expect(cells[4]).to have_content("Delivered")
      expect(cells[24]).to have_content("Delivered")
    end

    scenario "can filter mutliple columns at once" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      filters = page.all("rect", class: "unselected-filter-icon-border")
      filters[0].click(x: 5, y: 5)
      page.find("li", class: "cf-filter-option-row", text: "Hearing scheduled").click(x: 5, y: 5)
      filters[1].click(x: 5, y: 5)
      page.find("li", class: "cf-filter-option-row", text: "Text").click(x: 5, y: 5)
      table = page.find("tbody")
      cells = table.all("td")
      expect(table).to have_selector("tr", count: 1)
      expect(cells[0]).to have_content("Hearing scheduled")
      expect(cells[2]).to have_content("Text")
    end

    scenario "can sort by notification date" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      sort = page.all("svg", class: "table-icon")[1]
      sort.click(x: 5, y: 5)
      cell = page.all("td")[1]
      expect(cell).to have_content("11/08/2022")
    end

    scenario "can move to next page of notifications" do
      visit "queue/appeals/#{appeal.uuid}/notifications"
      click_on("Next", match: :first)
      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 1)
    end
  end
end
