# frozen_string_literal: true

RSpec.feature "Audit Lever History Table" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end
  before { Seeds::CaseDistributionLevers.new.seed! }

  let(:ama_direct_reviews) { Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals }
  let(:alternate_batch_size) { Constants.DISTRIBUTION.alternative_batch_size }

  let(:ama_direct_reviews_lever) { CaseDistributionLever.find_by_item(ama_direct_reviews) }
  let(:alternate_batch_size_lever) { CaseDistributionLever.find_by_item(alternate_batch_size) }

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
