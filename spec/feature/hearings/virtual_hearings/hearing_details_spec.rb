# frozen_string_literal: true

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
  let!(:expected_alert) do
    COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_TO_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
  end

  scenario "user switches hearing type to 'Virtual'" do
    visit "hearings/" + hearing.external_id.to_s + "/details"

    click_dropdown(name: "hearingType", index: 1)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE)

    fill_in "vet-email", with: "email@testingEmail.com"
    fill_in "rep-email", with: "email@testingEmail.com"
    click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

    expect(page).to have_content(expected_alert)

    hearing.reload
    expect(VirtualHearing.count).to eq(1)
    expect(hearing.virtual?).to eq(true)
    expect(hearing.virtual_hearing.veteran_email).to eq("email@testingEmail.com")
    expect(hearing.virtual_hearing.representative_email).to eq("email@testingEmail.com")
    expect(hearing.virtual_hearing.judge_email).to eq(nil)
  end

  context "for an existing Virtual Hearing" do
    let!(:virtual_hearing) { create(:virtual_hearing, :active, :all_emails_sent, conference_id: "0", hearing: hearing) }
    let!(:expected_alert) do
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_FROM_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
    end

    scenario "user switches hearing type back to original request type" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content("Change to")

      click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

      expect(page).to have_content(expected_alert)

      virtual_hearing.reload
      expect(virtual_hearing.cancelled?).to eq(true)
      expect(page).to have_content(hearing.readable_request_type)
    end
  end

  context "Hearing type dropdown and vet and poa fields are disabled while async job is running" do
    let!(:virtual_hearing) { create(:virtual_hearing, :pending, :all_emails_sent, hearing: hearing) }

    scenario "async job is not completed" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(find(".dropdown-hearingType")).to have_css(".is-disabled")
      expect(page).to have_field("Veteran Email", readonly: true)
      expect(page).to have_field("POA/Representive Email", readonly: true)
    end

    scenario "async job is completed" do
      virtual_hearing.update(status: :active)
      visit "hearings/" + hearing.external_id.to_s + "/details"
      hearing.reload
      expect(find(".dropdown-hearingType")).to have_no_css(".is-disabled")
      expect(page).to have_field("Veteran Email", readonly: false)
      expect(page).to have_field("POA/Representive Email", readonly: false)
    end
  end

  scenario "User can see and edit veteran and poa emails" do
    visit "hearings/" + hearing.external_id.to_s + "/details"

    click_dropdown(name: "hearingType", index: 1)
    fill_in "vet-email", with: "veteran@testingEmail.com"
    fill_in "rep-email", with: "rep@testingEmail.com"
    click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

    visit "hearings/" + hearing.external_id.to_s + "/details"

    expect(page).to have_field("Veteran Email", with: "veteran@testingEmail.com")
    expect(page).to have_field("POA/Representive Email", with: "rep@testingEmail.com")

    fill_in "Veteran Email", with: "new@email.com"
    click_button("Save")

    expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
    click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

    visit "hearings/" + hearing.external_id.to_s + "/details"

    expect(page).to have_field("Veteran Email", with: "new@email.com")
    expect(page).to have_field("POA/Representive Email", with: "rep@testingEmail.com")
  end
end
