# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket" do
  context "Hearing details is not editable for a non-hearings management user" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }
    let!(:hearing) { create(:hearing) }

    scenario "Fields are not editable" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      field_labeled("Notes", disabled: true)
    end
  end

  context "Hearing details for AMA hearing" do
    let!(:current_user) do
      OrganizationsUser.add_user_to_organization(create(:hearings_management), HearingsManagement.singleton)
      User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
    end
    let!(:hearing) { create(:hearing) }

    before do
      create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG")
      create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO")
    end

    scenario "User can update fields" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "judgeDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingRoomDropdown", index: 0, wait: 30)
      find("label", text: "Yes, Waive 90 Day Evidence Hold").click

      fill_in "Notes", with: generate_words(10)
      fill_in "taskNumber", with: "123456789"
      click_dropdown(name: "transcriber", index: 1)
      fill_in "sentToTranscriberDate", with: "04012019"
      fill_in "expectedReturnDate", with: "04022019"
      fill_in "uploadedToVbmsDate", with: "04032019"

      click_dropdown(name: "problemType", index: 1)
      fill_in "problemNoticeSentDate", with: "04042019"
      find(".cf-form-radio-option", text: "Proceeed without transcript").click

      find("label", text: "Yes, Transcript Requested").click
      fill_in "copySentDate", with: "04052019"

      click_button("Save")

      expect(page).to have_content("Hearing Successfully Updated")
    end
  end

  context "Hearing details for Legacy hearing" do
    let!(:current_user) do
      OrganizationsUser.add_user_to_organization(create(:hearings_management), HearingsManagement.singleton)
      User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
    end
    let!(:legacy_hearing) { create(:legacy_hearing) }

    scenario "User can update nothing" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"
      expect(page).to have_content("This is a Legacy Case Hearing")
    end
  end
end
