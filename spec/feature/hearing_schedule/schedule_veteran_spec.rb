require "rails_helper"

RSpec.feature "Schedule Veteran For A Hearing" do
  let!(:current_user) do
    OrganizationsUser.add_user_to_organization(hearings_user, HearingsManagement.singleton)
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  let!(:hearings_user) do
    create(:hearings_management)
  end

  context "When creating Caseflow Central hearings" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:vacols_case) do
      create(
        :case, :central_office_hearing,
        bfcorlid: "123454787S"
      )
    end

    scenario "Schedule Veteran for central hearing",
             skip: "This test passes on local but fails intermittently on circle" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(index: 7)
      click_button("Legacy Veterans Waiting")
      appeal_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      appeal_link.click
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")
      radio_link = find(".cf-form-radio-option", match: :first)
      radio_link.click
      click_button("Schedule")
      find_link("Back to Schedule Veterans").click
      expect(page).to have_content("Schedule Veterans")
      click_button("Scheduled Veterans")
      expect(VACOLS::Case.where(bfcorlid: "123454787S"))
      click_button("Legacy Veterans Waiting")
      expect(page).not_to have_content("123454787S")
      expect(page).to have_content("There are no schedulable veterans")
      expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey
    end
  end

  context "when video_hearing_requested" do
    let!(:hearing_day) do
      create(
        :hearing_day,
        request_type: "V",
        scheduled_for: Time.zone.today + 160,
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

    scenario "Schedule Veteran for video",
             skip: "This test passes on local but fails intermittently on circle" do
      visit "hearings/schedule/assign"
      expect(page).to have_content("Regional Office")
      click_dropdown(index: 12)
      click_button("Legacy Veterans Waiting")
      appeal_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      appeal_link.click
      expect(page).not_to have_content("loading to VACOLS.", wait: 30)
      expect(page).to have_content("Currently active tasks", wait: 30)
      click_dropdown(text: Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h[:label])
      expect(page).to have_content("Time")
      radio_link = find(".cf-form-radio-option", match: :first)
      radio_link.click
      click_button("Schedule")
      find_link("Back to Schedule Veterans").click
      expect(page).to have_content("Schedule Veterans")
      click_button("Scheduled Veterans")
      expect(VACOLS::Case.where(bfcorlid: "123456789S"))
      click_button("Legacy Veterans Waiting")
      expect(page).not_to have_content("123456789S")
      expect(page).to have_content("There are no schedulable veterans")
      expect(VACOLS::CaseHearing.first.folder_nr).to eq vacols_case.bfkey
    end
  end
end
