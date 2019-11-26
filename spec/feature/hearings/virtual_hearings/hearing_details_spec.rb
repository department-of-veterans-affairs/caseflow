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
    expect(page).to have_content("Change to Virtual Hearing")

    fill_in "vet-email", with: "email@testingEmail.com"
    fill_in "rep-email", with: "email@testingEmail.com"
    click_button("Change and Send Email")

    expect(page).to have_content(expected_alert)

    hearing.reload
    expect(VirtualHearing.count).to eq(1)
    expect(hearing.virtual?).to eq(true)
    expect(hearing.virtual_hearing.veteran_email).to eq("email@testingEmail.com")
    expect(hearing.virtual_hearing.representative_email).to eq("email@testingEmail.com")
    expect(hearing.virtual_hearing.judge_email).to eq(nil)
  end

  context "for an existing Virtual Hearing" do
    let!(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
    let!(:expected_alert) do
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_FROM_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
    end

    scenario "user switches hearing type back to original request type" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content("Change to")

      click_button("Change and Send Email")

      expect(page).to have_content(expected_alert)

      hearing.reload
      expect(hearing.virtual?).to eq(false)
      expect(page).to have_content(hearing.readable_request_type)
    end
  end
end
