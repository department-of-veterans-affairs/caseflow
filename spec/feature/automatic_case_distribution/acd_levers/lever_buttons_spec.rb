# frozen_string_literal: true

RSpec.feature "Case Distribution Controls Page Buttons" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:ama_direct_reviews) { Constants.DISTRIBUTION.ama_direct_review_docket_time_goals }
  let(:alternate_batch_size) { Constants.DISTRIBUTION.alternative_batch_size }

  let(:ama_direct_reviews_lever) { CaseDistributionLever.find_by_item(ama_direct_reviews) }
  let(:alternate_batch_size_lever) { CaseDistributionLever.find_by_item(alternate_batch_size) }

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded
      expect(page).not_to have_button("Cancel")
      expect(page).not_to have_button("Save")
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    let(:ama_direct_reviews_field) { Constants.DISTRIBUTION.ama_direct_review_docket_time_goals }
    let(:alternative_batch_size_field) { "#{Constants.DISTRIBUTION.alternative_batch_size}-field" }

    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
      ama_direct_reviews_lever.value = 100
      alternate_batch_size_lever.value = 10
      ama_direct_reviews_lever.save
      alternate_batch_size_lever.save
    end

    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded
      expect(page).to have_button("Cancel")
      expect(page).to have_button("Save", disabled: true)
    end

    scenario "changes a lever and then cancels the change" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field(ama_direct_reviews_field, with: "100")

      fill_in ama_direct_reviews_field, with: "123"
      expect(page).to have_field(ama_direct_reviews_field, with: "123")

      click_cancel_button
      expect(page).to have_field(ama_direct_reviews_field, with: "100")
    end

    scenario "changes two levers and then cancels the change" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field(ama_direct_reviews_field, with: "100")
      expect(page).to have_field(alternative_batch_size_field, with: "10")

      fill_in ama_direct_reviews_field, with: "123"
      fill_in alternative_batch_size_field, with: "12"
      expect(page).to have_field(ama_direct_reviews_field, with: "123")
      expect(page).to have_field(alternative_batch_size_field, with: "12")

      click_cancel_button
      expect(page).to have_field(ama_direct_reviews_field, with: "100")
      expect(page).to have_field(alternative_batch_size_field, with: "10")
    end

    scenario "changes a lever and then hits save" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field(ama_direct_reviews_field, with: "100")

      fill_in ama_direct_reviews_field, with: "123"
      expect(page).to have_field(ama_direct_reviews_field, with: "123")

      click_save_button
      expect(find("#case-distribution-control-modal-table-0")).to have_content("123")
    end

    scenario "changes two levers and then hits save" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field(ama_direct_reviews_field, with: "100")
      expect(page).to have_field(alternative_batch_size_field, with: "10")

      fill_in ama_direct_reviews_field, with: "123"
      fill_in alternative_batch_size_field, with: "13"
      expect(page).to have_field(ama_direct_reviews_field, with: "123")
      expect(page).to have_field(alternative_batch_size_field, with: "13")

      click_save_button
      expect(find("#case-distribution-control-modal-table-0")).to have_content("13")
      expect(find("#case-distribution-control-modal-table-1")).to have_content("123")
    end

    scenario "changes two levers and cancels on the modal screen" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field(ama_direct_reviews_field, with: "100")
      expect(page).to have_field(alternative_batch_size_field, with: "10")

      fill_in ama_direct_reviews_field, with: "123"
      fill_in alternative_batch_size_field, with: "13"
      expect(page).to have_field(ama_direct_reviews_field, with: "123")
      expect(page).to have_field(alternative_batch_size_field, with: "13")

      click_save_button
      expect(find("#case-distribution-control-modal-table-0")).to have_content("13")
      expect(find("#case-distribution-control-modal-table-1")).to have_content("123")

      click_modal_cancel_button
      expect(page).to have_field(ama_direct_reviews_field, with: "123")
      expect(page).to have_field(alternative_batch_size_field, with: "13")
    end

    scenario "changes two levers and confirms on the modal screen" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(page).to have_field(ama_direct_reviews_field, with: "100")
      expect(page).to have_field(alternative_batch_size_field, with: "10")

      fill_in ama_direct_reviews_field, with: "123"
      fill_in alternative_batch_size_field, with: "13"
      expect(page).to have_field(ama_direct_reviews_field, with: "123")
      expect(page).to have_field(alternative_batch_size_field, with: "13")

      click_save_button
      expect(find("#case-distribution-control-modal-table-0")).to have_content("13")
      expect(find("#case-distribution-control-modal-table-1")).to have_content("123")

      click_modal_confirm_button
      expect(page).to have_field(ama_direct_reviews_field, with: "123")
      expect(page).to have_field(alternative_batch_size_field, with: "13")
    end
  end
end

def confirm_page_and_section_loaded
  expect(page).to have_content(COPY::CASE_DISTRIBUTION_TITLE)
end

def click_cancel_button
  find("#CancelLeversButton").click
end

def click_save_button
  find("#LeversSaveButton").click
end

def click_modal_cancel_button
  find("#save-modal-cancel").click
end

def click_modal_confirm_button
  find("#save-modal-confirm").click
end
