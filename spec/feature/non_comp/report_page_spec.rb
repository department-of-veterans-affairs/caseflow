# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"
require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"
require_relative "../../../app/services/claim_change_history/change_history_filter_parser.rb"

feature "NonComp Report Page", :postgres do
  include DownloadHelpers
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:vha_report_url) { "/decision_reviews/vha/report" }

  before do
    clear_downloads
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
    visit vha_report_url
  end

  it "report page should be accessable to VHA Admin user" do
    # visit vha_report_url
    expect(page).to have_content("Generate task report")
    expect(page).to have_content("Type of report")

    step "should have a link that leads to saved searches" do
      click_link "View saved searches"
      expect(page).to have_content("SavedSearches")
    end
  end

  it "when report type dropdown is changed, the submit button should be enabled" do
    # visit vha_report_url
    expect(page).to have_button("Generate task report", disabled: true)
    expect(page).to have_button("Clear filters", disabled: true)
    click_dropdown(text: "Status")
    expect(page).to have_button("Generate task report")
    expect(page).to have_button("Clear filters")
  end

  it "report page should not be accessable to non admin VHA user" do
    OrganizationsUser.remove_admin_rights_from_user(user, non_comp_org)
    visit vha_report_url
    expect(current_url).to include("/unauthorized")
  end

  context "Form submission" do
    before do
      # CSV should be 17 lines
      create(:higher_level_review_vha_task_with_decision)
      create(:higher_level_review_vha_task_with_decision)
      create(:supplemental_claim_vha_task_with_decision)
    end

    it "should submit several types of event reports successfully and generate csvs for each submission" do
      expect(page).to have_content("Generate task report")
      # Start an event report
      click_dropdown(text: "Event / Action")
      expect(page).to have_content("Timing specifications")

      # Submit a report that should return all rows
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, and all 15 event rows
      change_history_csv_file(17)

      # Add in some specific event filters now
      fill_in_specific_event_filters(["Added issue", "Completed disposition"])

      # Submit a report that should only include rows for those two event types
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, and the 6 event rows
      change_history_csv_file(8)

      clear_filters

      # Select an event report again
      click_dropdown(text: "Event / Action")
      expect(page).to have_content("Timing specifications")

      # Add some conditions
      add_decision_review_condition_with_values(["Higher-Level Reviews"])
      add_issue_disposition_with_values(["Granted"])
      add_days_waiting_with_values("More than", 10)

      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      change_history_csv_file(6)

      # After submitting the form add one more condition and submit the form again
      add_personnel_condition_with_values([user.full_name])

      # Add blank condition and check to see if facilities is still available. It should not be
      add_condition
      dropdown = page.all(".cf-select__control").last
      dropdown.click
      expect(page).to_not have_content("Facility")

      # Remove the blank condition and submit the page again
      remove_last_condition
      expect(page).to_not have_content("Select a variable")
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      change_history_csv_file(2)
    end

    it "should submit several types of status reports successfully and generate CSVs for each submission" do
      expect(page).to have_content("Generate task report")
      # Start a status report
      click_dropdown(text: "Status")
      expect(page).to have_content("Select type of status report")

      # Submit a report that should only the last chronological event for each task
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, and one event row per task (3)
      change_history_csv_file(5)

      # Click the status Summary radio button
      find("label", text: "Summary").click
      # Submit a report that should include all events
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, all 15 event rows
      change_history_csv_file(17)

      # Select a specific status of cancelled
      fill_in_specific_status_filters(["Cancelled"])

      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, and 0 event rows
      change_history_csv_file(2)

      clear_filters

      click_dropdown(text: "Status")
      expect(page).to have_content("Select type of status report")

      # Add a condition or two
      add_days_waiting_with_values("Between", 5, 100)
      add_decision_review_condition_with_values(["Higher-Level Reviews"])
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, and the last two HLR event rows
      change_history_csv_file(4)

      # Add another condition that has no matches
      add_issue_disposition_with_values(["Denied"])
      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # Check the csv to make sure it returns the filter row, the column header row, all 0 event rows
      change_history_csv_file(2)
    end

    context "when request fails" do
      # Force an error
      before do
        allow_any_instance_of(DecisionReviewsController).to receive(:generate_report) do
          fail StandardError, "Error message"
        rescue StandardError => error
          { error: error.message }
        end
      end

      it "should display an error banner if an error occurs" do
        expect(page).to have_content("Generate task report")
        click_dropdown(text: "Event / Action")
        expect(page).to have_content("Timing specifications")

        click_button "Generate task report"
        expect(page).to have_content(
          "An error occurred, please try again. If the problem persists, submit a help desk ticket."
        )
      end
    end
  end

  def add_condition(type = nil)
    click_button("Add Condition")
    expect(page).to have_content("Select a variable")

    return unless type

    # Since this dropdown was just added, it will always be the last one
    dropdown = page.all(".cf-select__control").last
    dropdown.click

    expect(page).to have_content(type)
    click_dropdown_item_by_text(type)
    expect(dropdown.find("input", match: :first, visible: false)).to be_disabled
  end

  def remove_last_condition
    last_remove_condition_link = page.all("a", text: "Remove condition").last
    last_remove_condition_link.click
  end

  def click_dropdown_item_by_text(text)
    find(
      "div",
      class: "cf-select__option",
      text: text,
      exact_text: true
    ).click
  end

  # Example usage: add_days_waiting_with_values("Between", 1, 11)
  # add_days_waiting_with_values("More than", 10)
  def fill_in_days_waiting(time_range, number_of_days, end_days = nil)
    expect(page).to have_content("Time Range")
    days_waiting_div = find(".days-waiting")
    dropdown = days_waiting_div.find(".cf-select__control", match: :first)
    dropdown.click

    expect(days_waiting_div).to have_content(time_range)

    click_dropdown_item_by_text(time_range)
    if time_range == "Between"
      fill_in "Min days", with: number_of_days
      fill_in "Max days", with: end_days
    else
      fill_in "Number of days", with: number_of_days
    end
  end

  # Example usage: add_decision_review_condition_with_values(["Higher-Level Reviews", "Supplemental Claims"])
  def fill_in_decision_review_type(claim_types)
    expect(page).to have_content("Higher-Level Reviews")
    expect(page).to have_content("Supplemental Claims")
    check_checkboxes(claim_types)
  end

  def fill_in_specific_event_filters(events)
    find("label", text: "Specific Events / Actions").click
    check_checkboxes(events)
  end

  def fill_in_specific_status_filters(statuses)
    find("label", text: "Specific Status").click
    check_checkboxes(statuses)
  end

  def check_checkboxes(labels)
    checkbox_label_text_array = labels.is_a?(Array) ? labels : [labels]

    checkbox_label_text_array.each do |checkbox_label_text|
      find("label", text: checkbox_label_text, exact_text: true).click
    end
  end

  def fill_in_multi_select_condition(items, expected_text, content_selector)
    content_div = find(content_selector)
    expect(content_div).to have_content(expected_text)
    dropdown = content_div.find(".cf-select__control", match: :first)

    items_array = items.is_a?(Array) ? items : [items]

    items_array.each do |item|
      dropdown.click
      expect(content_div).to have_content(item)
      click_dropdown_item_by_text(item)
    end
  end

  # Example usage: add_facility_condition_with_values(["VACO"])
  def add_facility_condition_with_values(values)
    add_condition("Facility")
    fill_in_multi_select_condition(values, "Facility Type", ".facility")
  end

  def add_personnel_condition_with_values(values)
    add_condition("Personnel")
    fill_in_multi_select_condition(values, "VHA team members", ".personnel")
  end

  def add_decision_review_condition_with_values(values)
    add_condition("Decision Review Type")
    fill_in_multi_select_condition(values, "Decision Review Type", ".decision-review-types")
  end

  def add_days_waiting_with_values(time_range, num_days, end_days = nil)
    add_condition("Days Waiting")
    fill_in_days_waiting(time_range, num_days, end_days)
  end

  def add_issue_disposition_with_values(values)
    add_condition("Issue Disposition")
    fill_in_multi_select_condition(values, "Issue Disposition", ".issue-dispositions")
  end

  def add_issue_type_with_values(values)
    add_condition("Issue Type")
    fill_in_multi_select_condition(values, "Issue Type", ".issue-types")
  end

  def clear_filters
    click_button "Clear filters"
    expect(page).to have_content("Select...")
    expect(page).to have_button("Generate task report", disabled: true)
  end

  def latest_download
    downloads.max_by { |file| File.mtime(file) }
  end

  def download_csv
    wait_for_download
    CSV.read(latest_download)
  end

  def change_history_csv_file(rows)
    csv_file = download_csv
    expect(csv_file).to_not eq(nil)
    expect(csv_file.length).to eq(rows)
    clear_downloads
  end
end
