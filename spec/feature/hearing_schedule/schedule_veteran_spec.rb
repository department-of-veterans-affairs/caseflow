require "rails_helper"

RSpec.feature "Schedule Veteran For A Hearing" do
  let!(:current_user) do
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  def click_dropdown(opt_idx, container = page)
    dropdown = container.find(".Select-control")
    dropdown.click
    yield if block_given?
    dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{opt_idx}']").click
  end

  context "When creating Caseflow Central hearings" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:vacols_case) { create(:case, :central_office_hearing) }

    scenario "Schedule Veteran for central hearing" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown 7
      click_button("Schedule a Veteran")
      appeal_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      appeal_link.click
      expect(page).to have_content("Actions")
      click_dropdown 0
      expect(page).to have_content("Time")
      radio_link = find(".cf-form-radio-option", match: :first)
      radio_link.click
      click_button("Schedule")
      find_link("Back to Schedule Veterans").click
    end
  end

  context "when video_hearing_requested", focus: true do
    let!(:hearing_day) do
      create(
        :hearing_day,
        hearing_type: "V",
        hearing_date: Time.zone.today + 160,
        regional_office: "RO39"
      )
    end
    let!(:staff) { create(:staff, stafkey: "RO39", stc2: 2, stc3: 3, stc4: 4) }
    let!(:vacols_case) do
      create(
        :case, :video_hearing_requested,
        folder: create(:folder, tinum: "docket-number"),
        bfcorlid: "123456789S",
        bfregoff: "RO39"
      )
    end

    scenario "Schedule Veteran for video" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown 12
      click_button("Schedule a Veteran")
      appeal_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      appeal_link.click
      expect(page).to have_content("Actions")
      click_dropdown 0
      expect(page).to have_content("Time")
      radio_link = find(".cf-form-radio-option", match: :first)
      radio_link.click
      click_button("Schedule")
      find_link("Back to Schedule Veterans").click
    end
  end
end
