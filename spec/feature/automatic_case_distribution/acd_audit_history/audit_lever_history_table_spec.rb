# frozen_string_literal: true

RSpec.feature "Audit Lever History Table" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:ama_direct_reviews) { Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals }
  let(:alternate_batch_size) { Constants.DISTRIBUTION.alternative_batch_size }

  let(:ama_direct_reviews_lever) { CaseDistributionLever.find_by_item(ama_direct_reviews) }
  let(:alternate_batch_size_lever) { CaseDistributionLever.find_by_item(alternate_batch_size) }

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded
    end

    scenario "visits the lever control page with an audit lever history entry " do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: ama_direct_reviews_lever,
             previous_value: 10,
             update_value: 15)

      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("#lever-history-table")).to have_content(current_user.css_id)
      expect(find("#lever-history-table")).to have_content(ama_direct_reviews_lever.title)
      expect(find("#lever-history-table")).to have_content("10 #{ama_direct_reviews_lever.unit}")
      expect(find("#lever-history-table")).to have_content("15 #{ama_direct_reviews_lever.unit}")
    end

    scenario "visits the lever control page with an audit two lever history entries " do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: ama_direct_reviews_lever,
             previous_value: 15,
             update_value: 5)

      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: alternate_batch_size_lever,
             previous_value: 7,
             update_value: 6,
             created_at: Time.zone.now - 1.minute)

      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("#lever-history-table-row-0")).to have_content(current_user.css_id)
      expect(find("#lever-history-table-row-0")).to have_content(alternate_batch_size_lever.title)
      expect(find("#lever-history-table-row-0")).to have_content("7 #{alternate_batch_size_lever.unit}")
      expect(find("#lever-history-table-row-0")).to have_content("6 #{alternate_batch_size_lever.unit}")

      expect(find("#lever-history-table-row-1")).to have_content(current_user.css_id)
      expect(find("#lever-history-table-row-1")).to have_content(ama_direct_reviews_lever.title)
      expect(find("#lever-history-table-row-1")).to have_content("15 #{ama_direct_reviews_lever.unit}")
      expect(find("#lever-history-table-row-1")).to have_content("5 #{ama_direct_reviews_lever.unit}")
    end

    scenario "visits the lever control page with one audit lever history entry with two levers changed" do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: ama_direct_reviews_lever,
             previous_value: 9,
             update_value: 13)
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: alternate_batch_size_lever,
             previous_value: 2,
             update_value: 4)

      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("#lever-history-table-row-0")).to have_content(current_user.css_id)
      expect(find("#lever-history-table-row-0")).to have_content(alternate_batch_size_lever.title)
      expect(find("#lever-history-table-row-0")).to have_content("2 #{alternate_batch_size_lever.unit}")
      expect(find("#lever-history-table-row-0")).to have_content("4 #{alternate_batch_size_lever.unit}")

      expect(find("#lever-history-table-row-0")).to have_content(ama_direct_reviews_lever.title)
      expect(find("#lever-history-table-row-0")).to have_content("9 #{ama_direct_reviews_lever.unit}")
      expect(find("#lever-history-table-row-0")).to have_content("13 #{ama_direct_reviews_lever.unit}")
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    let(:ama_direct_reviews_field) { Constants.DISTRIBUTION.ama_direct_review_docket_time_goals }

    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "lever history displays on page", type: :feature do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      expect(find("#lever-history-table").has_no_content?("123 days")).to eq(true)
      expect(find("#lever-history-table").has_no_content?("300 days")).to eq(true)

      fill_in ama_direct_reviews_field, with: "123"
      click_save_button
      click_modal_confirm_button

      expect(find("#lever-history-table").has_content?("123 days")).to eq(true)
      expect(find("#lever-history-table").has_no_content?("300 days")).to eq(true)

      fill_in ama_direct_reviews_field, with: "300"
      click_save_button
      click_modal_confirm_button

      expect(find("#lever-history-table").has_content?("123 days")).to eq(true)
      expect(find("#lever-history-table").has_content?("300 days")).to eq(true)
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
