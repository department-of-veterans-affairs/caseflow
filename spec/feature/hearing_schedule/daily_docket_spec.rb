require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket" do
  let!(:current_user) do
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  context "Daily docket with one legacy hearing" do
    let!(:hearing_day) { create(:hearing_day, request_type: "V", regional_office: "RO39") }
    let!(:hearing_day_two) do
      create(:hearing_day,
             request_type: "V",
             regional_office: "RO39",
             scheduled_for: Date.new(2019, 4, 1))
    end
    let!(:case_hearing) { create(:case_hearing, vdkey: hearing_day.id) }
    let!(:staff) { create(:staff, stafkey: "RO39", stc2: 2, stc3: 3, stc4: 4) }

    scenario "User can update fields" do
      visit "hearings/schedule/docket/" + hearing_day.id.to_s
      find(".dropdown-Disposition").click
      find("#react-select-2--option-1").click
      fill_in "Notes", with: "This is a note about the hearing!"
      find("label", text: "8:30").click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Show")
      expect(page).to have_content("This is a note about the hearing!")
      # For unknown reasons, in feature tests, the hearing time is displayed as 3:30am. I
      # created a ticket that we can look into after February.
      # expect(page).to have_content("8:30 am")
    end

    scenario "User can postpone a hearing" do
      visit "hearings/schedule/docket/" + hearing_day.id.to_s
      find(".dropdown-Disposition").click
      find("#react-select-2--option-3").click
      find(".dropdown-HearingDay").click
      find("#react-select-4--option-2").click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      expect(page).to have_content("Previously Scheduled")
      new_hearing = VACOLS::CaseHearing.find_by(vdkey: hearing_day_two.id)
      expect(new_hearing.folder_nr).to eql(case_hearing.folder_nr)
    end
  end

  context "Daily docket with one AMA hearing" do
    let!(:hearing) { create(:hearing) }
    let!(:postponed_hearing_day) { create(:hearing_day, scheduled_for: Date.new(2019, 3, 3)) }

    scenario "User can update fields" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      find(".dropdown-Disposition").click
      find("#react-select-2--option-1").click
      fill_in "Notes", with: "This is a note about the hearing!"
      find("label", text: "9:00").click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Show")
      expect(page).to have_content("This is a note about the hearing!")
      # For unknown reasons, in feature tests, the hearing time is displayed as 3:30am. I
      # created a ticket that we can look into after February.
      # expect(page).to have_content("8:30 am")
    end

    scenario "User can postpone a hearing" do
      visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
      find(".dropdown-Disposition").click
      find("#react-select-2--option-3").click
      find(".dropdown-HearingDay").click
      find("#react-select-4--option-2").click
      click_button("Save")

      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      expect(page).to have_content("Previously Scheduled")
      new_hearing = Hearing.find_by(hearing_day: postponed_hearing_day)
      expect(new_hearing.appeal).to eql(hearing.appeal)
    end
  end
end
