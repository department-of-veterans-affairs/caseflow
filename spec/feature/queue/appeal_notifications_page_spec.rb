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
    let(:ama_notifications_page) { "queue/appeals/#{appeal.uuid}/notifications" }
    let(:seed_ama_notifications) do
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-01",
                            event_type: "Appeal docketed", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: "555-555-5555",
                            email_notification_status: "delivered", sms_notification_status: "delivered",
                            notification_content: "Your appeal at the Board of Veteran's Appeals has been docketed. "\
                            "We must work cases in the order your VA Form 9 substantive appeal (for Legacy) or VA "\
                            "Form 10182 (for AMA) was received. We will update you with any progress. If you have "\
                            "any questions please reach out to your Veterans Service Organization or representative "\
                            "or log onto VA.gov for additional information.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-02",
                            event_type: "Hearing scheduled", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "Your hearing has been scheduled with a Veterans Law Judge at the "\
                            "Board of Veterans' Appeals. You will be notified of the details in writing shortly.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-03",
                            event_type: "Privacy Act request pending", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative filed a Privacy Act request. The Board "\
                            "placed your appeal on hold until this request is satisfied.")
      create(:notification, appeals_id: appeal.uuid, appeals_type: "Appeal", event_date: "2022-11-04",
                            event_type: "Privacy Act request complete", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
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

    before(:example) do
      appeal
    end

    context "without notifications" do
      scenario "notification page link will not show up" do
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_no_link("View notifications sent to appellant")
      end
    end

    context "with notifications" do
      before(:example) do
        seed_ama_notifications
      end

      scenario "visits notifications page for ama appeal" do
        visit "queue/appeals/#{appeal.uuid}"
        click_link("View notifications sent to appellant")
        page.switch_to_window(page.windows.last)
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/notifications")
      end

      scenario "sees correct event type in first row of table" do
        visit(ama_notifications_page)
        cell = page.find("td", match: :first)
        expect(cell).to have_content("Appeal docketed")
      end

      scenario "sees correct notification date in first row of table" do
        visit(ama_notifications_page)
        cell = page.all("td", minimum: 1)[1]
        expect(cell).to have_content("11/01/2022")
      end

      scenario "sees correct notification type in first row of table" do
        visit(ama_notifications_page)
        cell = page.all("td", minimum: 1)[2]
        expect(cell).to have_content("Email")
      end

      scenario "sees correct recipient information in first row of table" do
        visit(ama_notifications_page)
        cell = page.all("td", minimum: 1)[3]
        expect(cell).to have_content("example@example.com")
      end

      scenario "sees correct status in first row of table" do
        visit(ama_notifications_page)
        cell = page.all("td", minimum: 1)[4]
        expect(cell).to have_content("Delivered")
      end

      scenario "table is filled with a full page of notifications" do
        visit(ama_notifications_page)
        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 15)
      end

      scenario "can filter by event type" do
        visit(ama_notifications_page)
        filter = page.find("rect", class: "unselected-filter-icon-border", match: :first)
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Appeal docketed")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 2)
        expect(cells[0]).to have_content("Appeal docketed")
        expect(cells[5]).to have_content("Appeal docketed")
      end

      scenario "can filter by notification type" do
        visit(ama_notifications_page)
        filter = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)[1]
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Email")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 8)
        expect(cells[2]).to have_content("Email")
        expect(cells[37]).to have_content("Email")
      end

      scenario "can filter by recipient information" do
        visit(ama_notifications_page)
        filter = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)[2]
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Example@example.com")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 4)
        expect(cells[3]).to have_content("example@example.com")
        expect(cells[18]).to have_content("example@example.com")
      end

      scenario "can filter by status" do
        visit(ama_notifications_page)
        filter = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)[3]
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Delivered")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 5)
        expect(cells[4]).to have_content("Delivered")
        expect(cells[24]).to have_content("Delivered")
      end

      scenario "can filter mutliple columns at once" do
        visit(ama_notifications_page)
        filters = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)
        filters[0].click(x: 5, y: 5)
        page.find("li", class: "cf-filter-option-row", text: "Hearing scheduled").click(x: 5, y: 5)
        filters[1].click(x: 5, y: 5)
        page.find("li", class: "cf-filter-option-row", text: "Text").click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 1)
        expect(cells[0]).to have_content("Hearing scheduled")
        expect(cells[2]).to have_content("Text")
      end

      scenario "can sort by notification date" do
        visit(ama_notifications_page)
        sort = page.all("svg", class: "table-icon", minimum: 1)[1]
        sort.click(x: 5, y: 5)
        cell = page.all("td", minimum: 1)[1]
        expect(cell).to have_content("11/08/2022")
      end

      scenario "can move to next page of notifications" do
        visit(ama_notifications_page)
        click_on("Next", match: :first)
        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)
      end

      scenario "clicking on a numbered page button will render that page" do
        visit(ama_notifications_page)
        pagination = page.find(class: "cf-pagination-pages", match: :first)
        pagination.find("Button", text: "2", match: :first).click
        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)
      end

      scenario "next button disabled when on the last page" do
        visit(ama_notifications_page)
        click_on("Next", match: :first)
        expect(page).to have_button("Next", disabled: true)
      end

      scenario "prev button moves to previous page" do
        visit(ama_notifications_page)
        click_on("Next", match: :first)
        click_on("Prev", match: :first)
        cell = page.find("td", match: :first)
        expect(cell).to have_content("Appeal docketed")
      end

      scenario "prev button disabled on the first page" do
        visit(ama_notifications_page)
        expect(page).to have_button("Prev", disabled: true)
      end

      scenario "modal appears when clicking on an event type" do
        visit(ama_notifications_page)
        cell = page.find("td", match: :first)
        cell.click
        expect(page).to have_selector("div", class: "cf-modal-body")
      end

      scenario "background darkened and disables clicking after opening modal" do
        visit(ama_notifications_page)
        cell = page.find("td", match: :first)
        cell.click
        expect(page).to have_selector("section", id: "modal_id")
      end

      scenario "closing the modal should remove the dark background and the modal" do
        visit(ama_notifications_page)
        cell = page.find("td", match: :first)
        cell.click
        click_on("Close")
        expect(page).not_to have_selector("div", class: "cf-modal-body")
        expect(page).not_to have_selector("section", id: "modal_id")
      end
    end
  end

  context "legacy appeal" do
    let(:legacy_appeal) do
      create(:legacy_appeal, :with_veteran,
             vacols_case: create(:case, :aod))
    end
    let(:legacy_notifications_page) { "queue/appeals/#{legacy_appeal.vacols_id}/notifications" }
    let(:seed_legacy_notifications) do
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-01",
                            event_type: "Appeal docketed", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: "555-555-5555",
                            email_notification_status: "delivered", sms_notification_status: "delivered",
                            notification_content: "Your appeal at the Board of Veteran's Appeals has been docketed. "\
                            "We must work cases in the order your VA Form 9 substantive appeal (for Legacy) or VA "\
                            "Form 10182 (for AMA) was received. We will update you with any progress. If you have "\
                            "any questions please reach out to your Veterans Service Organization or representative "\
                            "or log onto VA.gov for additional information.")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-02",
                            event_type: "Hearing scheduled", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "Your hearing has been scheduled with a Veterans Law Judge at the "\
                            "Board of Veterans' Appeals. You will be notified of the details in writing shortly.")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-03",
                            event_type: "Privacy Act request pending", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative filed a Privacy Act request. The Board "\
                            "placed your appeal on hold until this request is satisfied.")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-04",
                            event_type: "Privacy Act request complete", notification_type: "Email and SMS",
                            recipient_email: "example@example.com", recipient_phone_number: nil,
                            email_notification_status: "delivered", sms_notification_status: "temporary-failure",
                            notification_content: "The Privacy Act request has been satisfied and the Board will "\
                            "continue processing your appeal at this time. The Board must work cases in docket order "\
                            "(the order received) If you have any questions please reach out to your Veterans Service "\
                            "Organization or representative, if you have one, or log onto VA.gov for additional "\
                            "information")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-05",
                            event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "temporary-failure",
                            notification_content: "You or your representative have requested to withdraw your hearing "\
                            "request. The Board will continue processing your appeal, but it must work cases in "\
                            "docket order (the order received). For more information please reach out to your "\
                            "Veterans Service Organization or representative, if you have one, or contact the "\
                            "hearing coordinator for your region. For a list of hearing coordinators by region "\
                            "with contact information, please visit https://www.bva.va.gov.")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-06",
                            event_type: "VSO IHP pending", notification_type: "Email and SMS", recipient_email: nil,
                            recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "You filed an appeal with the Board of Veterans' Appeals. Your case "\
                            "has been assigned to your Veterans Service Organization to provide written argument. "\
                            "Once the argument has been received, the Board of Veterans' Appeals will resume "\
                            "processing of your appeal.")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-07",
                            event_type: "VSO IHP complete", notification_type: "Email and SMS",
                            recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
                            sms_notification_status: "Success",
                            notification_content: "The Board of Veterans' Appeals received the written argument from "\
                            "your Veterans Service Organization. The Board will continue processing your appeal, but "\
                            "it must work cases in docket order (the order received). If you have any questions "\
                            "please reach out to your Veterans Service Organization or log onto VA.gov for additional "\
                            "information.")
      create(:notification, appeals_id: legacy_appeal.vacols_id, appeals_type: "LegacyAppeal", event_date: "2022-11-08",
                            event_type: "Appeal decision mailed (Non-contested claims)",
                            notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil,
                            email_notification_status: "Success", sms_notification_status: "permanent-failure",
                            notification_content: "The Board of Veterans' Appeals issued a decision on your appeal "\
                            "that will be sent to you and to your representative, if you have one, shortly.")
    end

    before(:example) do
      legacy_appeal
    end

    context "without notifications" do
      scenario "notification page link will not show up" do
        visit "queue/appeals/#{legacy_appeal.vacols_id}"
        expect(page).to have_no_link("View notifications sent to appellant")
      end
    end

    context "with notifications" do
      before(:example) do
        seed_legacy_notifications
      end

      scenario "visits notifications page for legacy appeal" do
        visit "queue/appeals/#{legacy_appeal.vacols_id}"
        click_link("View notifications sent to appellant")
        page.switch_to_window(page.windows.last)
        expect(page).to have_current_path("/queue/appeals/#{legacy_appeal.vacols_id}/notifications")
      end

      scenario "sees correct event type in first row of table" do
        visit(legacy_notifications_page)
        cell = page.find("td", match: :first)
        expect(cell).to have_content("Appeal docketed")
      end

      scenario "sees correct notification date in first row of table" do
        visit(legacy_notifications_page)
        cell = page.all("td", minimum: 1)[1]
        expect(cell).to have_content("11/01/2022")
      end

      scenario "sees correct notification type in first row of table" do
        visit(legacy_notifications_page)
        cell = page.all("td", minimum: 1)[2]
        expect(cell).to have_content("Email")
      end

      scenario "sees correct recipient information in first row of table" do
        visit(legacy_notifications_page)
        cell = page.all("td", minimum: 1)[3]
        expect(cell).to have_content("example@example.com")
      end

      scenario "sees correct status in first row of table" do
        visit(legacy_notifications_page)
        cell = page.all("td", minimum: 1)[4]
        expect(cell).to have_content("Delivered")
      end

      scenario "table is filled with a full page of notifications" do
        visit(legacy_notifications_page)
        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 15)
      end

      scenario "can filter by event type" do
        visit(legacy_notifications_page)
        filter = page.find("rect", class: "unselected-filter-icon-border", match: :first)
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Appeal docketed")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 2)
        expect(cells[0]).to have_content("Appeal docketed")
        expect(cells[5]).to have_content("Appeal docketed")
      end

      scenario "can filter by notification type" do
        visit(legacy_notifications_page)
        filter = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)[1]
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Email")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 8)
        expect(cells[2]).to have_content("Email")
        expect(cells[37]).to have_content("Email")
      end

      scenario "can filter by recipient information" do
        visit(legacy_notifications_page)
        filter = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)[2]
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Example@example.com")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 4)
        expect(cells[3]).to have_content("example@example.com")
        expect(cells[18]).to have_content("example@example.com")
      end

      scenario "can filter by status" do
        visit(legacy_notifications_page)
        filter = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)[3]
        filter.click(x: 5, y: 5)
        filter_option = page.find("li", class: "cf-filter-option-row", text: "Delivered")
        filter_option.click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 5)
        expect(cells[4]).to have_content("Delivered")
        expect(cells[24]).to have_content("Delivered")
      end

      scenario "can filter mutliple columns at once" do
        visit(legacy_notifications_page)
        filters = page.all("rect", class: "unselected-filter-icon-border", minimum: 1)
        filters[0].click(x: 5, y: 5)
        page.find("li", class: "cf-filter-option-row", text: "Hearing scheduled").click(x: 5, y: 5)
        filters[1].click(x: 5, y: 5)
        page.find("li", class: "cf-filter-option-row", text: "Text").click(x: 5, y: 5)
        table = page.find("tbody")
        cells = table.all("td", minimum: 1)
        expect(table).to have_selector("tr", count: 1)
        expect(cells[0]).to have_content("Hearing scheduled")
        expect(cells[2]).to have_content("Text")
      end

      scenario "can sort by notification date" do
        visit(legacy_notifications_page)
        sort = page.all("svg", class: "table-icon", minimum: 1)[1]
        sort.click(x: 5, y: 5)
        cell = page.all("td", minimum: 1)[1]
        expect(cell).to have_content("11/08/2022")
      end

      scenario "can move to next page of notifications" do
        visit(legacy_notifications_page)
        click_on("Next", match: :first)
        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)
      end

      scenario "clicking on a numbered page button will render that page" do
        visit(legacy_notifications_page)
        pagination = page.find(class: "cf-pagination-pages", match: :first)
        pagination.find("Button", text: "2", match: :first).click
        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)
      end

      scenario "next button disabled when on the last page" do
        visit(legacy_notifications_page)
        click_on("Next", match: :first)
        expect(page).to have_button("Next", disabled: true)
      end

      scenario "prev button moves to previous page" do
        visit(legacy_notifications_page)
        click_on("Next", match: :first)
        click_on("Prev", match: :first)
        cell = page.find("td", match: :first)
        expect(cell).to have_content("Appeal docketed")
      end

      scenario "prev button disabled on the first page" do
        visit(legacy_notifications_page)
        expect(page).to have_button("Prev", disabled: true)
      end

      scenario "modal appears when clicking on an event type" do
        visit(legacy_notifications_page)
        cell = page.find("td", match: :first)
        cell.click
        expect(page).to have_selector("div", class: "cf-modal-body")
      end

      scenario "background darkened and disables clicking after opening modal" do
        visit(legacy_notifications_page)
        cell = page.find("td", match: :first)
        cell.click
        expect(page).to have_selector("section", id: "modal_id")
      end

      scenario "closing the modal should remove the dark background and the modal" do
        visit(legacy_notifications_page)
        cell = page.find("td", match: :first)
        cell.click
        click_on("Close")
        expect(page).not_to have_selector("div", class: "cf-modal-body")
        expect(page).not_to have_selector("section", id: "modal_id")
      end
    end
  end
end
