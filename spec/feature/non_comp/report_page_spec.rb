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

      # prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
      # text = Constants.TASK_ACTIONS.CANCEL_TASK.label
      # click_dropdown(prompt: prompt, text: text)
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
    dropdown = find(".days-waiting").find(".cf-select__control").first
    dropdown.click
    click_dropdown_item_by_text(time_range)
    fill_in
  end
end
