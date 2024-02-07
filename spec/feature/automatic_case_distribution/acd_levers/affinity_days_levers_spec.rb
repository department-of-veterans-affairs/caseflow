# frozen_string_literal: true

RSpec.feature "Affinity Days Levers" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:ama_hearing_case_affinity_days) {Constants.DISTRIBUTION.ama_hearing_case_affinity_days}
  let(:ama_hearing_case_aod_affinity_days) {Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days}
  let(:cavc_affinity_days) {Constants.DISTRIBUTION.cavc_affinity_days}
  let(:cavc_aod_affinity_days) {Constants.DISTRIBUTION.cavc_aod_affinity_days}
  let(:aoj_affinity_days) {Constants.DISTRIBUTION.aoj_affinity_days}
  let(:aoj_aod_affinity_days) {Constants.DISTRIBUTION.aoj_aod_affinity_days}
  let(:aoj_cavc_affinity_days) {Constants.DISTRIBUTION.aoj_cavc_affinity_days}

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("##{ama_hearing_case_affinity_days}")).to match_css('.lever-disabled')
      expect(find("##{ama_hearing_case_aod_affinity_days}")).to match_css('.lever-disabled')
      expect(find("##{cavc_affinity_days}")).to match_css('.lever-disabled')
      expect(find("##{cavc_aod_affinity_days}")).to match_css('.lever-disabled')
      expect(find("##{aoj_affinity_days}")).to match_css('.lever-disabled')
      expect(find("##{aoj_aod_affinity_days}")).to match_css('.lever-disabled')
      expect(find("##{aoj_cavc_affinity_days}")).to match_css('.lever-disabled')
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the lever control page" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      omit = Constants.ACD_LEVERS.omit
      infinite = Constants.ACD_LEVERS.infinite
      value = Constants.ACD_LEVERS.value

      disabled_lever_list = [ama_hearing_case_affinity_days, ama_hearing_case_aod_affinity_days, cavc_affinity_days,
        cavc_aod_affinity_days, aoj_affinity_days, aoj_aod_affinity_days, aoj_cavc_affinity_days]
      option_list = [omit, infinite, value]


      disabled_lever_list.each do |disabled_lever|
        option_list do |option|
          expect(find("##{disabled_lever}-#{option}", visible: false)).to be_disabled
        end
      end
    end
  end
end

def confirm_page_and_section_loaded
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_AFFINITY_DAYS_H2_TITLE)
  expect(page).to have_content(Constants.DISTRIBUTION.ama_hearing_case_affinity_days_title)
  expect(page).to have_content(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days_title)
  expect(page).to have_content(Constants.DISTRIBUTION.cavc_affinity_days_title)
  expect(page).to have_content(Constants.DISTRIBUTION.cavc_aod_affinity_days_title)
  expect(page).to have_content(Constants.DISTRIBUTION.aoj_affinity_days_title)
  expect(page).to have_content(Constants.DISTRIBUTION.aoj_aod_affinity_days_title)
  expect(page).to have_content(Constants.DISTRIBUTION.aoj_cavc_affinity_days_title)
end
