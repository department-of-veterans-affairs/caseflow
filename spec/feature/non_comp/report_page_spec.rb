# frozen_string_literal: true

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
    visit vha_report_url
    expect(page).to have_content("Generate task report")
    expect(page).to have_content("Type of report")
  end

  it "when report type dropdown is changed, the submit button should be enabled" do
    visit vha_report_url
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
      # visit vha_report_url
    end

    it "should sumbmit an event report including a personnel condition" do
      # visit vha_report_url
      # visit vha_report_url
      expect(page).to have_content("Generate task report")
      click_dropdown(text: "Event / Action")
      expect(page).to have_content("Timing specifications")

      add_condition("Days Waiting")
      fill_in_days_waiting("More than", 10)

      add_condition("Personnel")
      fill_in_personnel([user.full_name])

      expect(page).to have_button("Generate task report", disabled: false)
      click_button "Generate task report"

      # This might happen too fast for capybara
      expect(page).to have_button("Generate task report", disabled: true)
      expect(page).to have_content("Generating CSV...")


      # Wait for the download somewhere?? and grab it

    end
  end

  def add_condition(type = nil)
    click_button("Add Condition")
    expect(page).to have_content("Select a variable")

    return unless type

    # Since this dropdown was just added, it will always be the last one
    dropdown = page.all(".cf-select__control").last
    dropdown.click

    # find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click

    expect(page).to have_content(type)
    click_dropdown_item_by_text(type)
    expect(dropdown.find("input", match: :first, visible: false)).to be_disabled
  end

  def click_dropdown_item_by_text(text)
    find(
      "div",
      class: "cf-select__option",
      text: text
    ).click
  end

  def fill_in_days_waiting(time_range, number_of_days)
    # dropdown = find(".days-waiting .cf-select__control").first
    expect(page).to have_content("Time Range")
    days_waiting_div = find(".days-waiting")
    dropdown = days_waiting_div.find(".cf-select__control", match: :first)
    dropdown.click

    expect(days_waiting_div).to have_content(time_range)

    click_dropdown_item_by_text(time_range)
    fill_in "Number of days", with: number_of_days
  end

  def fill_in_personnel(user_names)
    expect(page).to have_content("VHA team members")
    personnel_div = find(".personnel")
    dropdown = personnel_div.find(".cf-select__control", match: :first)

    names_array = user_names.is_a?(Array) ? user_names : [user_names]

    names_array.each do |user_name|
      dropdown.click
      expect(days_waiting_div).to have_content(user_name)
      click_dropdown_item_by_text.text(user_name)
    end
  end
end
