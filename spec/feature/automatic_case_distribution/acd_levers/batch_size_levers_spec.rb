# frozen_string_literal: true

RSpec.feature "Batch Size Levers" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:alternate_batch_size) { Constants.DISTRIBUTION.alternative_batch_size }
  let(:batch_size_per_attorney) { Constants.DISTRIBUTION.batch_size_per_attorney }
  let(:request_more_cases_minimum) { Constants.DISTRIBUTION.request_more_cases_minimum }

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("##{alternate_batch_size} > label")).to match_css(".lever-active")
      expect(find("##{batch_size_per_attorney} > label")).to match_css(".lever-active")
      expect(find("##{request_more_cases_minimum} > label")).to match_css(".lever-active")
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the lever control page" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field("#{alternate_batch_size}-field", readonly: false)
      expect(page).to have_field("#{batch_size_per_attorney}-field", readonly: false)
      expect(page).to have_field("#{request_more_cases_minimum}-field", readonly: false)
    end

    scenario "changes the Batch Size levers values to an valid input" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).not_to have_field("#{alternate_batch_size}-field", with: "42")
      expect(page).not_to have_field("#{batch_size_per_attorney}-field", with: "32")
      expect(page).not_to have_field("#{request_more_cases_minimum}-field", with: "25")

      fill_in "#{alternate_batch_size}-field", with: "42"
      fill_in "#{batch_size_per_attorney}-field", with: "32"
      fill_in "#{request_more_cases_minimum}-field", with: "25"

      expect(page).to have_field("#{alternate_batch_size}-field", with: "42")
      expect(page).to have_field("#{batch_size_per_attorney}-field", with: "32")
      expect(page).to have_field("#{request_more_cases_minimum}-field", with: "25")
    end

    scenario "changes the Batch Size levers values to a invalid inputs" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      empty_error_message = "Please enter a value greater than or equal to 0"

      CaseDistributionLever.find_by_item(alternate_batch_size)
      CaseDistributionLever.find_by_item(batch_size_per_attorney)
      CaseDistributionLever.find_by_item(request_more_cases_minimum)

      fill_in "#{alternate_batch_size}-field", with: "ABC"
      fill_in "#{batch_size_per_attorney}-field", with: "-1"
      fill_in "#{request_more_cases_minimum}-field", with: "(*&)"

      expect(page).to have_field("#{alternate_batch_size}-field", with: "")
      expect(page).to have_field("#{batch_size_per_attorney}-field", with: "1")
      expect(page).to have_field("#{request_more_cases_minimum}-field", with: "")

      expect(find("##{alternate_batch_size} > div > div > span")).to have_content(empty_error_message)
      expect(find("##{request_more_cases_minimum} > div > div > span")).to have_content(empty_error_message)
    end
  end
end

def confirm_page_and_section_loaded
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_BATCH_SIZE_H2_TITLE)
  expect(page).to have_content(Constants.DISTRIBUTION.alternative_batch_size_title)
  expect(page).to have_content(Constants.DISTRIBUTION.batch_size_per_attorney_title)
  expect(page).to have_content(Constants.DISTRIBUTION.request_more_cases_minimum_title)
end
