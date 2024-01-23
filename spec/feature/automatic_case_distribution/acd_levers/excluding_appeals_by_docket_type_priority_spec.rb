# frozen_string_literal: true

RSpec.feature "Excluding Appeals by Docket Type and Priority from Automatic Case Distribution Levers" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:all_priority) {Constants.DISTRIBUTION.all_priority_id}
  let(:all_non_priority) {Constants.DISTRIBUTION.all_non_priority_id}

  let(:legacy_appeals) {Constants.DISTRIBUTION.legacy_appeals_id}
  let(:ama_hearings_appeals) {Constants.DISTRIBUTION.ama_hearings_appeals_id}
  let(:ama_direct_review_appeals) {Constants.DISTRIBUTION.ama_direct_review_appeals_id}
  let(:ama_evidence_submission_appeals) {Constants.DISTRIBUTION.ama_evidence_submission_appeals_id}

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("##{all_non_priority}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{legacy_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{ama_hearings_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{ama_direct_review_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{ama_evidence_submission_appeals}")).to match_css('.lever-disabled')

      expect(find("##{all_priority}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{legacy_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{ama_hearings_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{ama_direct_review_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{ama_evidence_submission_appeals}")).to match_css('.lever-disabled')
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the lever control page" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("##{all_non_priority}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-switch")).to be_disabled
      expect(find("##{all_non_priority}-#{legacy_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{ama_hearings_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{ama_direct_review_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_non_priority}-#{ama_evidence_submission_appeals}")).to match_css('.lever-disabled')

      expect(find("##{all_priority}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-switch")).to be_disabled
      expect(find("##{all_priority}-#{legacy_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{ama_hearings_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{ama_direct_review_appeals}")).to match_css('.lever-disabled')
      expect(find("##{all_priority}-#{ama_evidence_submission_appeals}")).to match_css('.lever-disabled')

    end
  end
end



def confirm_page_and_section_loaded
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_EXCLUSION_TABLE_TITLE)
  expect(page).to have_content(Constants.DISTRIBUTION.all_non_priority)
  expect(page).to have_content(Constants.DISTRIBUTION.all_priority)

  expect(page).to have_content(COPY::CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER)
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER)
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER)
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_EVIDENCE_HEADER)
end
