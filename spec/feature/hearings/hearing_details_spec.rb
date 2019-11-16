# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket", :all_dbs do
  let(:user) { create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  before do
    create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG")
    create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO")
  end

  context "Hearing details is not editable for a non-hearings management user" do
    let!(:current_user) { User.authenticate!(user: user) }
    let!(:hearing) { create(:hearing, :with_tasks) }

    scenario "Fields are not editable" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to have_field("Notes", disabled: true)
    end
  end

  context "Hearing details for AMA hearing" do
    let!(:current_user) do
      HearingsManagement.singleton.add_user(user)
      User.authenticate!(user: user)
    end
    let!(:hearing) { create(:hearing, :with_tasks) }

    scenario "User can update fields", skip: "Test is flakey" do
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
      HearingsManagement.singleton.add_user(user)
      User.authenticate!(user: user)
      FeatureToggle.enable!(:schedule_virtual_hearings)
    end

    let!(:judge) { create(:user, station_id: User::BOARD_STATION_ID, email: "judge@testingEmail.com") }
    let!(:legacy_hearing) { create(:legacy_hearing, :with_tasks, user: judge, regional_office: "RO06") }

    scenario "User can edit Judge and change virtual hearings" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"

      expect(page).to have_field("judgeDropdown", disabled: false)
      expect(page).to have_field("hearingCoordinatorDropdown", disabled: false)
      expect(page).to have_field("hearingRoomDropdown", disabled: false)
      expect(page).to have_field("Notes", disabled: false)
      expect(page).to have_no_selector("label", text: "Yes, Waive 90 Day Evidence Hold")

      click_dropdown(name: "hearingType", index: 1)
      expect(page).to have_content("Change to Virtual Hearing")

      fill_in "vet-email", with: "email@testingEmail.com"
      fill_in "rep-email", with: "email@testingEmail.com"
      click_button("Change and Send Email")

      expect(page).to have_content("Hearing Successfully Updated")

      legacy_hearing.reload
      expect(VirtualHearing.count).to eq(1)
      expect(legacy_hearing.virtual?).to eq(true)
      expect(legacy_hearing.virtual_hearing.veteran_email).to eq("email@testingEmail.com")
      expect(legacy_hearing.virtual_hearing.representative_email).to eq("email@testingEmail.com")
    end

    scenario "User can select judge, hearing room, hearing coordinator, and add notes" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"

      click_dropdown(name: "judgeDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingRoomDropdown", index: 0, wait: 30)

      fill_in "Notes", with: generate_words(10)

      click_button("Save")
      expect(page).to have_content("Hearing Successfully Updated")
    end

    scenario "User can not edit transcription" do
      visit "hearings/" + legacy_hearing.external_id.to_s + "/details"

      expect(page).to have_no_field("taskNumber")
      expect(page).to have_no_field("transcriber")
      expect(page).to have_no_field("sentToTranscriberDate")
      expect(page).to have_no_field("expectedReturnDate")
      expect(page).to have_no_field("uploadedToVbmsDate")
      expect(page).to have_no_field("problemType")
      expect(page).to have_no_field("problemNoticeSentDate")
      expect(page).to have_no_field("requestedRemedy")
      expect(page).to have_no_field("copySentDate")
      expect(page).to have_no_field("copyRequested")
    end
  end
end
