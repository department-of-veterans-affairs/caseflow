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

  scenario "user switches hearing type to 'Virtual'" do
    visit "hearings/" + hearing.external_id.to_s + "/details"

    click_dropdown(name: "hearingType", index: 1)
    expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE)

    fill_in "vet-email", with: "email@testingEmail.com"
    fill_in "rep-email", with: "email@testingEmail.com"
    click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

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
    let!(:virtual_hearing) { create(:virtual_hearing, conference_id: "0", hearing: hearing) }

    scenario "user switches hearing type back to original request type" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content("Change to")

      click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

      expect(page).to have_content("Hearing Successfully Updated")

      virtual_hearing.reload
      expect(virtual_hearing.cancelled?).to eq(true)
      expect(page).to have_content(hearing.readable_request_type)
    end
  end

  context "Veteran and POA email field are disabled until conference is created" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing,
        hearing: hearing,
        representative_email_sent: true,
        veteran_email_sent: true,
        judge_email_sent: true,
        status: :pending
      )
    end

    scenario "conference has not been created yet" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to have_field("Veteran Email", readonly: true)
      expect(page).to have_field("POA/Representive Email", readonly: true )
    end

    scenario "conference was created" do
      virtual_hearing.update(status: :active)
      visit "hearings/" + hearing.external_id.to_s + "/details"
      hearing.reload
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
    expect(page).to have_field("POA/Representive Email", with:"rep@testingEmail.com")
  end
end
