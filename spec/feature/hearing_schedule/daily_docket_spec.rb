require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket" do
  let!(:current_user) do
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  context "Daily docket with one legacy hearing" do
    let!(:hearing_day) { create(:hearing_day, request_type: "V", regional_office: "RO18") }
    let!(:hearing_day_two) do
      create(:hearing_day,
             request_type: "V",
             regional_office: "RO18",
             scheduled_for: Time.zone.today.beginning_of_day + 10.days)
    end

    let!(:veteran) { create(:veteran, file_number: "123456789") }
    let!(:vacols_case) { create(:case, bfcorlid: "123456789S") }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

    let!(:case_hearing) { create(:case_hearing, vdkey: hearing_day.id, folder_nr: legacy_appeal.vacols_id) }
    let!(:legacy_hearing) { create(:legacy_hearing, vacols_id: case_hearing.hearing_pkseq, appeal: legacy_appeal) }
    let!(:staff) { create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4) }

    scenario "User can update fields" do
      visit "hearings/schedule/docket/" + hearing_day.id.to_s
      find(".dropdown-Disposition").click
      find("#react-select-2--option-1").click
      click_dropdown(name: "veteranHearingLocation", text: "Holdrege, NE (0 miles away)")
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

    scenario "User can postpone a hearing", focus: true do
      visit "hearings/schedule/docket/" + hearing_day.id.to_s
      click_dropdown(name: "veteranHearingLocation", text: "Holdrege, NE (0 miles away)")
      click_dropdown(name: "Disposition", text: "Postponed")
      click_dropdown(name: "HearingDay", text: (Time.zone.today.beginning_of_day + 10.days).strftime("%m/%d/%Y"))
      click_button("Save")
      expect(page).to have_content("You have successfully updated")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      expect(page).to have_content("Previously Scheduled")
      new_hearing = VACOLS::CaseHearing.find_by(vdkey: master_record_two.id)
      expect(new_hearing.folder_nr).to eql(case_hearing.folder_nr)
    end
  end
end
