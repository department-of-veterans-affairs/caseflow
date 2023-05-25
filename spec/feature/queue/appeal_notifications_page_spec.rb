# frozen_string_literal: true

require "spec_helper"

RSpec.feature "Notifications View" do
  let(:user_roles) { ["System Admin"] }
  before { User.authenticate!(roles: user_roles) }

  shared_examples "without notifications" do
    it "notification page link will not show up" do
      visit appeal_case_details_page
      expect(page).to have_no_link("View notifications sent to appellant")
    end
  end

  shared_examples "with notifications" do
    let(:seed_notifications) do
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-01",
                            event_type: "Appeal docketed", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: "555-555-5555",
                            email_notification_status: "delivered", sms_notification_status: "delivered",
                            notification_content: "Your appeal at the Board of Veteran's Appeals has been docketed. "\
                            "We must work cases in the order your VA Form 9 substantive appeal (for Legacy) or VA "\
                            "Form 10182 (for AMA) was received. We will update you with any progress. If you have "\
                            "any questions please reach out to your Veterans Service Organization or representative "\
                            "or log onto VA.gov for additional information.")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-02",
                            event_type: "Hearing scheduled", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "Your hearing has been scheduled with a Veterans Law Judge at the "\
                            "Board of Veterans' Appeals. You will be notified of the details in writing shortly.")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-03",
                            event_type: "Privacy Act request pending", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative filed a Privacy Act request. The Board "\
                            "placed your appeal on hold until this request is satisfied.")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-04",
                            event_type: "Privacy Act request complete", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "The Privacy Act request has been satisfied and the Board will "\
                            "continue processing your appeal at this time. The Board must work cases in docket order "\
                            "(the order received) If you have any questions please reach out to your Veterans Service "\
                            "Organization or representative, if you have one, or log onto VA.gov for additional "\
                            "information")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-05",
                            event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative have requested to withdraw your hearing "\
                            "request. The Board will continue processing your appeal, but it must work cases in "\
                            "docket order (the order received). For more information please reach out to your "\
                            "Veterans Service Organization or representative, if you have one, or contact the "\
                            "hearing coordinator for your region. For a list of hearing coordinators by region "\
                            "with contact information, please visit https://www.bva.va.gov.")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-06",
                            event_type: "VSO IHP pending", notification_type: "Email and SMS", recipient_email: nil,
                            recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "You filed an appeal with the Board of Veterans' Appeals. Your case "\
                            "has been assigned to your Veterans Service Organization to provide written argument. "\
                            "Once the argument has been received, the Board of Veterans' Appeals will resume "\
                            "processing of your appeal.")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-07",
                            event_type: "VSO IHP complete", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "The Board of Veterans' Appeals received the written argument from "\
                            "your Veterans Service Organization. The Board will continue processing your appeal, but "\
                            "it must work cases in docket order (the order received). If you have any questions "\
                            "please reach out to your Veterans Service Organization or log onto VA.gov for additional "\
                            "information.")
      create(:notification, appeals_id: appeals_id, appeals_type: appeal.class.name, event_date: "2022-11-08",
                            event_type: "Appeal decision mailed (Non-contested claims)",
                            notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil,
                            email_notification_status: "Success", sms_notification_status: "permanent-failure",
                            notification_content: "The Board of Veterans' Appeals issued a decision on your appeal "\
                            "that will be sent to you and to your representative, if you have one, shortly.")
    end

    before do
      Seeds::NotificationEvents.new.seed!
      seed_notifications
    end

    it "notifications page link appears, page has full table with correct information, and can sort by date" do
      visit appeal_case_details_page
      click_link("View notifications sent to appellant")
      # notifications page opens in new browser window so go to that window
      page.switch_to_window(page.windows.last)
      expect(page).to have_current_path(appeal_notifications_page)

      # table is filled with notifications
      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 15)

      # correct event type
      event_type_cell = page.find("td", match: :first)
      expect(event_type_cell).to have_content("Appeal docketed")

      # correct notification date
      date_cell = page.all("td", minimum: 1)[1]
      expect(date_cell).to have_content("11/01/2022")

      # correct notification type
      notification_type_cell = page.all("td", minimum: 1)[2]
      expect(notification_type_cell).to have_content("Email")

      # correct recipient information
      recipient_info_cell = page.all("td", minimum: 1)[3]
      expect(recipient_info_cell).to have_content("example@example.com")

      # correct status
      status_cell = page.all("td", minimum: 1)[4]
      expect(status_cell).to have_content("Delivered")

      # sort by notification date
      sort = page.all("svg", class: "table-icon", minimum: 1)[1]
      sort.click
      cell = page.all("td", minimum: 1)[1]
      expect(cell).to have_content("11/08/2022")
    end

    it "table can filter by each column, and filter by multiple columns at once" do
      visit appeal_case_details_page
      click_link("View notifications sent to appellant")
      # notifications page opens in new browser window so go to that window
      page.switch_to_window(page.windows.last)
      expect(page).to have_current_path(appeal_notifications_page)

      # by event type
      filter = page.find("path", class: "unselected-filter-icon-inner-1", match: :first)
      filter.click
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Appeal docketed")
      filter_option.click
      table = page.find("tbody")
      cells = table.all("td", minimum: 1)
      expect(table).to have_selector("tr", count: 2)
      expect(cells[0]).to have_content("Appeal docketed")
      expect(cells[5]).to have_content("Appeal docketed")

      # clear filter
      filter.click
      page.find("button", text: "Clear Event filter").click

      # by notification type
      filter = page.all("path", class: "unselected-filter-icon-inner-1", minimum: 1)[1]
      filter.click
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Email")
      filter_option.click
      table = page.find("tbody")
      cells = table.all("td", minimum: 1)
      expect(table).to have_selector("tr", count: 8)
      expect(cells[2]).to have_content("Email")
      expect(cells[37]).to have_content("Email")

      # clear filter
      filter.click
      page.find("button", text: "Clear Notification type filter").click

      # by recipient information
      filter = page.all("path", class: "unselected-filter-icon-inner-1", minimum: 1)[2]
      filter.click
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Example@example.com")
      filter_option.click
      table = page.find("tbody")
      cells = table.all("td", minimum: 1)
      expect(table).to have_selector("tr", count: 4)
      expect(cells[3]).to have_content("example@example.com")
      expect(cells[18]).to have_content("example@example.com")

      # clear filter
      filter.click
      page.find("button", text: "Clear Recipient information filter").click

      # by status
      filter = page.all("path", class: "unselected-filter-icon-inner-1", minimum: 1)[3]
      filter.click
      filter_option = page.find("li", class: "cf-filter-option-row", text: "Delivered")
      filter_option.click
      table = page.find("tbody")
      cells = table.all("td", minimum: 1)
      expect(table).to have_selector("tr", count: 5)
      expect(cells[4]).to have_content("Delivered")
      expect(cells[24]).to have_content("Delivered")

      # clear filter
      filter.click
      page.find("button", text: "Clear Status filter").click

      # by multiple columns at once
      filters = page.all("path", class: "unselected-filter-icon-inner-1", minimum: 1)
      filters[0].click
      page.find("li", class: "cf-filter-option-row", text: "Hearing scheduled").click
      filters[1].click
      page.find("li", class: "cf-filter-option-row", text: "Text").click
      table = page.find("tbody")
      cells = table.all("td", minimum: 1)
      expect(table).to have_selector("tr", count: 1)
      expect(cells[0]).to have_content("Hearing scheduled")
      expect(cells[2]).to have_content("Text")
    end

    it "notification page can properly navigate pages and event modal behaves properly" do
      visit appeal_case_details_page
      click_link("View notifications sent to appellant")
      # notifications page opens in new browser window so go to that window
      page.switch_to_window(page.windows.last)
      expect(page).to have_current_path(appeal_notifications_page)

      # next button moves to next page
      click_on("Next", match: :first)
      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 1)

      # next button disabled while on last page
      expect(page).to have_button("Next", disabled: true)

      # prev button moves to previous page
      click_on("Prev", match: :first)
      event_type_cell = page.find("td", match: :first)
      expect(event_type_cell).to have_content("Appeal docketed")

      # prev button disabled on the first page
      expect(page).to have_button("Prev", disabled: true)

      # clicking numbered page button renders correct page
      pagination = page.find(class: "cf-pagination-pages", match: :first)
      pagination.find("Button", text: "2", match: :first).click
      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 1)

      # modal appears when clicking on an event type
      event_type_cell = page.find("td", match: :first).find("a")
      event_type_cell.click
      expect(page).to have_selector("div", class: "cf-modal-body")

      # background darkens and disables clicking when modal is open
      expect(page).to have_selector("section", id: "modal_id")

      # clicking close button on modal removes dark background and closes modal
      click_on("Close")
      expect(page).not_to have_selector("div", class: "cf-modal-body")
      expect(page).not_to have_selector("section", id: "modal_id")
    end
  end

  # rubocop:disable Style/BlockDelimiters
  context "ama appeal" do
    let(:appeal) { create(:appeal) }
    let(:appeals_id) { appeal.uuid }
    let(:appeal_case_details_page) { "/queue/appeals/#{appeal.uuid}" }
    let(:appeal_notifications_page) { "/queue/appeals/#{appeal.uuid}/notifications" }

    before { appeal }

    context "without notifications" do include_examples "without notifications"; end

    context "with notifications" do include_examples "with notifications"; end
  end

  context "legacy appeal" do
    let(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case, :aod)) }
    let(:appeals_id) { appeal.vacols_id }
    let(:appeal_case_details_page) { "/queue/appeals/#{appeal.vacols_id}" }
    let(:appeal_notifications_page) { "/queue/appeals/#{appeal.vacols_id}/notifications" }

    before { appeal }

    context "without notifications" do include_examples "without notifications"; end

    context "with notifications" do include_examples "with notifications"; end
  end
  # rubocop:enable Style/BlockDelimiters
end
