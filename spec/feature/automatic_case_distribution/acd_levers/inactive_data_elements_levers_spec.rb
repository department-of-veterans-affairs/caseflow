# frozen_string_literal: true

RSpec.feature "Excluding Appeals by Docket Type and Priority from Automatic Case Distribution Levers" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:maximum_direct_review_proportion) { Constants.DISTRIBUTION.maximum_direct_review_proportion }
  let(:minimum_legacy_proportion) { Constants.DISTRIBUTION.minimum_legacy_proportion }
  let(:nod_adjustment) { Constants.DISTRIBUTION.nod_adjustment }
  let(:bust_backlog) { Constants.DISTRIBUTION.bust_backlog }

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      description_product_match
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the lever control page" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      description_product_match
    end

    scenario "confirms the displayed values of the levers" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      maximum_direct_review_proportion_lever = CaseDistributionLever.find_by_item(maximum_direct_review_proportion)
      minimum_legacy_proportion_lever = CaseDistributionLever.find_by_item(minimum_legacy_proportion)
      nod_adjustment_lever = CaseDistributionLever.find_by_item(nod_adjustment)
      bust_backlog_lever = CaseDistributionLever.find_by_item(bust_backlog)

      converted_maximum_direct_review_proportion_value =
        (maximum_direct_review_proportion_lever.value.to_f * 100).to_i.to_s
      converted_minimum_legacy_proportion_value = (minimum_legacy_proportion_lever.value.to_f * 100).to_i.to_s
      converted_nod_adjustment_value = (nod_adjustment_lever.value.to_f * 100).to_i.to_s
      bust_backlog_value = bust_backlog_lever.value.humanize

      expect(find("##{maximum_direct_review_proportion}-value")).to have_content(
        converted_maximum_direct_review_proportion_value + maximum_direct_review_proportion_lever.unit
      )
      expect(find("##{minimum_legacy_proportion}-value")).to have_content(
        converted_minimum_legacy_proportion_value + minimum_legacy_proportion_lever.unit
      )
      expect(find("##{nod_adjustment}-value")).to have_content(
        converted_nod_adjustment_value + nod_adjustment_lever.unit
      )
      expect(find("##{bust_backlog}-value")).to have_content(bust_backlog_value + bust_backlog_lever.unit)
    end
  end
end

# rubocop:disable Metrics/AbcSize
def description_product_match
  expect(find("##{maximum_direct_review_proportion}-description")).to match_css(".description-styling")
  expect(find("##{maximum_direct_review_proportion}-product")).to match_css(".value-styling")

  expect(find("##{minimum_legacy_proportion}-description")).to match_css(".description-styling")
  expect(find("##{minimum_legacy_proportion}-product")).to match_css(".value-styling")

  expect(find("##{nod_adjustment}-description")).to match_css(".description-styling")
  expect(find("##{nod_adjustment}-product")).to match_css(".value-styling")

  expect(find("##{bust_backlog}-description")).to match_css(".description-styling")
  expect(find("##{bust_backlog}-product")).to match_css(".value-styling")
end

def confirm_page_and_section_loaded
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_STATIC_LEVERS_TITLE)
  expect(page).to have_content(Constants.DISTRIBUTION.maximum_direct_review_proportion_title)
  expect(page).to have_content(Constants.DISTRIBUTION.minimum_legacy_proportion_title)
  expect(page).to have_content(Constants.DISTRIBUTION.nod_adjustment_title)
  expect(page).to have_content(Constants.DISTRIBUTION.bust_backlog_title)
end
# rubocop:enable Metrics/AbcSize
