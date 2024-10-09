# frozen_string_literal: true

RSpec.feature "Admin UI" do
  before { Seeds::CaseDistributionLevers.new.seed! }

  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:enabled_lever_list) do
    [
      Constants.DISTRIBUTION.ama_hearing_case_affinity_days,
      Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days,
      Constants.DISTRIBUTION.cavc_aod_affinity_days,
      Constants.DISTRIBUTION.cavc_affinity_days,
      Constants.DISTRIBUTION.aoj_affinity_days,
      Constants.DISTRIBUTION.aoj_aod_affinity_days,
      Constants.DISTRIBUTION.aoj_cavc_affinity_days
    ]
  end

  let(:ama_hearings) { Constants.DISTRIBUTION.ama_hearing_start_distribution_prior_to_goals }
  let(:ama_direct_reviews) { Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals }
  let(:ama_evidence_submissions) { Constants.DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals }

  let(:ama_hearings_field) { Constants.DISTRIBUTION.ama_hearing_docket_time_goals }
  let(:ama_direct_reviews_field) { Constants.DISTRIBUTION.ama_direct_review_docket_time_goals }
  let(:ama_evidence_submissions_field) { Constants.DISTRIBUTION.ama_evidence_submission_docket_time_goals }

  let(:alternate_batch_size) { Constants.DISTRIBUTION.alternative_batch_size }
  let(:batch_size_per_attorney) { Constants.DISTRIBUTION.batch_size_per_attorney }
  let(:request_more_cases_minimum) { Constants.DISTRIBUTION.request_more_cases_minimum }

  let(:ama_direct_reviews_lever) { CaseDistributionLever.find_by_item(ama_direct_reviews) }
  let(:alternate_batch_size_lever) { CaseDistributionLever.find_by_item(alternate_batch_size) }

  let(:maximum_direct_review_proportion) { Constants.DISTRIBUTION.maximum_direct_review_proportion }
  let(:minimum_legacy_proportion) { Constants.DISTRIBUTION.minimum_legacy_proportion }
  let(:nod_adjustment) { Constants.DISTRIBUTION.nod_adjustment }
  let(:bust_backlog) { Constants.DISTRIBUTION.bust_backlog }

  let(:alternative_batch_size_field) { "#{Constants.DISTRIBUTION.alternative_batch_size}-field" }

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    it "the lever control page operates correctly" do
      visit "case-distribution-controls"
      expect(page).to have_content("Case Distribution Algorithm Values")

      EMPTY_ERROR_MESSAGE = "Please enter a value greater than or equal to 0"

      step "enabled levers display correctly" do
        # From affinity_days_levers_spec.rb
        option_list = [Constants.ACD_LEVERS.omit, Constants.ACD_LEVERS.infinite, Constants.ACD_LEVERS.value]

        enabled_lever_list.each do |enabled_lever|
          option_list.each do |option|
            expect(find("##{enabled_lever}-#{option}", visible: false)).not_to be_disabled
          end
        end
      end

      step "levers initally are enabled and display correctly" do
        expect(page).to have_field(ama_hearings_field.to_s, disabled: false)
        expect(page).to have_field(ama_direct_reviews_field.to_s)
        expect(page).to have_field(ama_evidence_submissions_field.to_s, disabled: false)

        expect(page).to have_button("toggle-switch-#{ama_hearings}", disabled: false)
        expect(page).to have_button("toggle-switch-#{ama_direct_reviews}", disabled: false)
        expect(page).to have_button("toggle-switch-#{ama_evidence_submissions}", disabled: false)
      end

      step "inactive levers are displayed with values" do
        expect(find("##{maximum_direct_review_proportion}-value")).to have_content("7%")
        expect(find("##{minimum_legacy_proportion}-value")).to have_content("90%")
        expect(find("##{nod_adjustment}-value")).to have_content("40%")
        expect(find("##{bust_backlog}-value")).to have_content("True")
      end

      step "cancelling lever changes resets values" do
        # Capybara locally is not setting clearing the field prior to entering the new value so fill with ""
        fill_in ama_direct_reviews_field, with: ""

        fill_in ama_direct_reviews_field, with: "123"
        expect(page).to have_field(ama_direct_reviews_field, with: "123")
        click_cancel_button
        expect(page).to have_field(ama_direct_reviews_field, with: "365")

        fill_in ama_direct_reviews_field, with: "123"
        fill_in alternative_batch_size_field, with: ""
        fill_in alternative_batch_size_field, with: "12"
        expect(page).to have_field(ama_direct_reviews_field, with: "123")
        expect(page).to have_field(alternative_batch_size_field, with: "12")

        click_cancel_button
        expect(page).to have_field(ama_direct_reviews_field, with: "365")
        expect(page).to have_field(alternative_batch_size_field, with: "15")
      end

      step "cancelling changes on confirm modal returns user to page without resetting the values in the fields" do
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

      step "error displays for invalid input on time goals section" do
        fill_in ama_direct_reviews_field, with: "ABC"
        expect(page).to have_field(ama_direct_reviews_field, with: "")
        expect(find("##{ama_direct_reviews_field}-lever")).to have_content(EMPTY_ERROR_MESSAGE)

        fill_in ama_direct_reviews_field, with: "-1"
        expect(page).to have_field(ama_direct_reviews_field, with: "1")
        expect(find("##{ama_direct_reviews_field}-lever").has_no_content?(EMPTY_ERROR_MESSAGE)).to eq(true)
      end

      step "time goals section error clears with valid input" do
        expect(find("#lever-history-table").has_no_content?("123 days")).to eq(true)
        expect(find("#lever-history-table").has_no_content?("300 days")).to eq(true)

        # Change two levers at once to satisfy a previously separate test
        fill_in ama_direct_reviews_field, with: ""
        fill_in ama_direct_reviews_field, with: "123"
        fill_in ama_evidence_submissions_field, with: "456"
        click_save_button
        click_modal_confirm_button
        expect(page).to have_content(COPY::CASE_DISTRIBUTION_SUCCESS_BANNER_TITLE)
      end

      step "lever history displays on page" do
        expect(page.find("#lever-history-table").has_content?("15 cases")).to be true
        expect(page.find("#lever-history-table").has_content?("365 days")).to be true
        expect(page.find("#lever-history-table").has_content?("550 days")).to be true
        expect(page.find("#lever-history-table").has_content?("13 cases")).to be true
        expect(page.find("#lever-history-table").has_content?("123 days")).to be true
        expect(page.find("#lever-history-table").has_content?("456 days")).to be true
      end

      step "batch size lever section errors display with invalid inputs" do
        expect(page).to have_field("#{alternate_batch_size}-field", readonly: false)
        expect(page).to have_field("#{batch_size_per_attorney}-field", readonly: false)
        expect(page).to have_field("#{request_more_cases_minimum}-field", readonly: false)

        fill_in "#{alternate_batch_size}-field", with: "ABC"
        fill_in "#{batch_size_per_attorney}-field", with: "-1"
        fill_in "#{request_more_cases_minimum}-field", with: "(*&)"

        expect(page).to have_field("#{alternate_batch_size}-field", with: "")
        expect(page).to have_field("#{batch_size_per_attorney}-field", with: "1")
        expect(page).to have_field("#{request_more_cases_minimum}-field", with: "")

        expect(find("##{alternate_batch_size} > div > div > span")).to have_content(EMPTY_ERROR_MESSAGE)
        expect(find("##{request_more_cases_minimum} > div > div > span")).to have_content(EMPTY_ERROR_MESSAGE)
      end

      step "batch size lever section errors clear with valid inputs" do
        fill_in "#{alternate_batch_size}-field", with: "42"
        fill_in "#{batch_size_per_attorney}-field", with: "32"
        fill_in "#{request_more_cases_minimum}-field", with: "25"

        expect(page).not_to have_content(EMPTY_ERROR_MESSAGE)
      end
    end
  end

  def click_save_button
    find("#LeversSaveButton").click
  end

  def click_modal_confirm_button
    find("#save-modal-confirm").click
  end

  def click_cancel_button
    find("#CancelLeversButton").click
  end

  def click_modal_cancel_button
    find("#save-modal-cancel").click
  end
end
