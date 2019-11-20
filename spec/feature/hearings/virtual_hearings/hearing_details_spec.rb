# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Editing Virtual Hearings from Hearing Details", :all_dbs do
  let(:current_user) { create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  before do
    create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG")
    create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO")
    HearingsManagement.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO13") }

  scenario "user switches hearing type to 'Virtual'" do
    visit "hearings/" + hearing.external_id.to_s + "/details"

    click_dropdown(name: "hearingType", index: 1)
    expect(page).to have_content("Change to Virtual Hearing")

    fill_in "vet-email", with: "email@testingEmail.com"
    fill_in "rep-email", with: "email@testingEmail.com"
    click_button("Change and Send Email")

    expect(page).to have_content("Hearing Successfully Updated")

    hearing.reload
    expect(VirtualHearing.count).to eq(1)
    expect(hearing.virtual?).to eq(true)
    expect(hearing.virtual_hearing.veteran_email).to eq("email@testingEmail.com")
    expect(hearing.virtual_hearing.representative_email).to eq("email@testingEmail.com")
    expect(hearing.virtual_hearing.judge_email).to eq(nil)
    expect(page).to have_content("Virtual")
  end

  context "for an existing Virtual Hearing" do
    let!(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }

    scenario "user switches hearing type back to original request type" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content("Change to")

      click_button("Change and Send Email")

      expect(page).to have_content("Hearing Successfully Updated")

      hearing.reload
      expect(hearing.virtual?).to eq(false)
      expect(page).to have_content(hearing.readable_request_type)
    end
  end

  scenario "User can edit veteran and poa emails", focus: true do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "hearingType", index: 1)
      fill_in "vet-email", with: "email@testingEmail.com"
      click_button("Change and Send Email")

      expect(page).to have_field("Veteran Email", disabled: false)
      expect(page).to have_field("POA/Representive Email", disabled: false)

      # fill_in "Veteran Email", with: "newVeteran@gmail.com"
      # fill_in "POA/Representive Email", with: "newRepresentative@gmail.com"

      # click_button("Save")

      # expect(page).to have_content("newVeteran@gmail.com")
      # expect(page).to have_content("newRepresentative@gmail.com")

      hearing.reload
      expect(hearing.virtual_hearing.active?).to eq(true)
      expect(hearing.virtual_hearing.all_emails_sent?).to eq(true)
    end
end
