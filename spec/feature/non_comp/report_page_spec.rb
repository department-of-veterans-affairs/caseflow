# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"
require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"

feature "NonComp Report Page", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user) }
  let(:vha_report_url) { "/decision_reviews/vha/report" }

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
    visit vha_report_url
  end

  it "report page should be accessable to VHA Admin user" do
    # visit vha_report_url
    expect(page).to have_content("Generate task report")
    expect(page).to have_content("Type of report")
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
      # visit vha_report_url
      # visit vha_report_url
      expect(page).to have_content("Generate task report")
      click_dropdown(text: "Event / Action")
      expect(page).to have_content("Timing specifications")

      # add_condition("Days Waiting")
      # fill_in_days_waiting("More than", 10)
      # add_days_waiting_with_values("More than", 10)
      # add_days_waiting_with_values("Between", 1, 11)

      # add_condition("Decision Review Type")
      # fill_in_decision_review_type(["Higher-Level Reviews", "Supplemental Claims"])
      # add_decision_review_condition_with_values(["Higher-Level Reviews", "Supplemental Claims"])

      # add_condition("Personnel")
      # fill_in_multi_select_condition([user.full_name], "VHA team members", ".personnel")
      # add_personnel_condition_with_values([user.full_name])

      # # Add blank condition and check to see if facilities is still available
      # add_condition

      # dropdown = page.all(".cf-select__control").last
      # dropdown.click

      # expect(page).to_not have_content("Facility")

      # remove_last_condition

      # expect(page).to_not have_content("Select a variable")

      # add_condition("Facility")
      # fill_in_multi_select_condition(["VACO"], "Facility Type", ".facility")
      # add_facility_condition_with_values(["VACO"])

      # There are two VACO's in these options
      # fill_in_multi_select_condition([/\A#{Regexp.escape("VACO")}\z/], "Facility Type", ".facility")

      # add_issue_disposition_with_values(["Granted"])

      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # This might happen too fast for capybara
      # expect(page).to have_button("Generate task report", disabled: true)
      # expect(page).to have_content("Generating CSV...")

      csv_file = change_history_csv_file

      # CSV.foreach(csv_file) do |row|
      #   puts "Row: #{row}"
      # end

      number_of_rows = CSV.read(csv_file).length
      expect(number_of_rows).to eq(17)
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

    checkbox_label_text_array = claim_types.is_a?(Array) ? claim_types : [claim_types]

    checkbox_label_text_array.each do |checkbox_label_text|
      find("label", text: checkbox_label_text).click
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
    fill_in_decision_review_type(values)
  end

  def add_days_waiting_with_values(time_range, num_days, end_days = nil)
    add_condition("Days Waiting")
    fill_in_days_waiting(time_range, num_days, end_days)
  end

  def add_issue_disposition_with_values(values)
    add_condition("Issue Disposition")
    fill_in_multi_select_condition(values, "Issue Disposition", ".issue-dispositions")
  end

  def change_history_csv_file
    # This time might have to be adjusted
    sleep(2)
    # Copied from Capybara setup
    download_directory = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}")
    list_of_files = Dir.glob(File.join(download_directory, "*")).select { |f| File.file?(f) }
    latest_file = list_of_files.max_by { |f| File.birthtime(f) }

    expect(latest_file).to_not eq(nil)
    latest_file
  end
end
