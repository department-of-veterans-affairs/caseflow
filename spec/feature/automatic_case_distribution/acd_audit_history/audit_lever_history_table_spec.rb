# frozen_string_literal: true

RSpec.feature "AMA Non-priority Distribution Goals by Docket Levers" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "lever history displays on page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).not_to have_content("123 days")
      expect(page).not_to have_content("300 days")

      fill_in ama_direct_reviews_field, with: "123"
      click_save_button
      click_modal_confirm_button

      expect(page).to have_content("123 days")
      expect(page).not_to have_content("300 days")

      fill_in ama_direct_reviews_field, with: "300"
      click_save_button
      click_modal_confirm_button

      expect(page).to have_content("123 days")
      expect(page).to have_content("300 days")
    end
  end
end

def confirm_page_and_section_loaded
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_HISTORY_TITLE)
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_HISTORY_DESCRIPTION)
end

def click_save_button
  find("#LeversSaveButton").click
end

def click_modal_confirm_button
  find("#save-modal-confirm").click
end
