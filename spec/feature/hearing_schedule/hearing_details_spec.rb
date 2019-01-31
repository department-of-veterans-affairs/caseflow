require "rails_helper"

RSpec.feature "Hearing Schedule Hearing Details", focus: true do
  let!(:current_user) do
    OrganizationsUser.add_user_to_organization(create(:hearings_management), HearingsManagement.singleton)
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  let!(:veteran) { create(:veteran, file_number: "123456789") }
  let!(:staff) { create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4) }
  let!(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today) }

  context "Hearing details for AMA hearing" do
    let(:hearing) { create(:hearing, hearing_day: hearing_day) }

    scenario "User can update fields" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "judgeDropdown", index: 0)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0)
      click_dropdown(name: "hearingRoomDropdown", index: 0)
      click_checkbox(name: "evidenceWindowWaived")

      fill_in "Notes", with: generate_words(10)
      fill_in "taskNumber", with: "123456789"
      click_dropdown(name: "transcriber", index: 1)
      fill_in "sentToTranscriberDate", with: "04012019"
      fill_in "expectedReturnDate", with: "04022019"
      fill_in "uploadedToVbmsDate", with: "04032019"

      click_dropdown(name: "problemType", index: 1)
      fill_in "problemNoticeSentDate", with: "04042019"
      find(".cf-form-radio-option", text: "Proceeed without transcript").click

      click_checkbox(name: "copyRequested")
      fill_in "copySentDate", with: "04052019"

      click_button("Save")
    end

    context "Hearing details for Legacy hearing" do
      let!(:vacols_hearing_day) { create(:case_hearing, hearing_type: "C", folder_nr: "VIDEO RO18") }
      let!(:vacols_case) { create(:case, bfcorlid: "123456789S") }
      let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let!(:case_hearing) do
        create(:case_hearing, vdkey: hearing_day.hearing_pkseq, folder_nr: legacy_appeal.vacols_id)
      end
      let!(:legacy_hearing) { create(:legacy_hearing, vacols_id: case_hearing.hearing_pkseq, appeal: legacy_appeal) }

      scenario "User can update nothing" do
        visit "hearings/" + legacy_hearing.external_id.to_s + "/details"

      end
    end
  end
end
