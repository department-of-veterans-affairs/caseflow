# frozen_string_literal: true

RSpec.feature "Admin UI" do
  before { Seeds::CaseDistributionLevers.new.seed! }

  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:disabled_lever_list) do
    [
      Constants.DISTRIBUTION.aoj_affinity_days,
      Constants.DISTRIBUTION.aoj_aod_affinity_days,
      Constants.DISTRIBUTION.aoj_cavc_affinity_days
    ]
  end

  let(:enabled_lever_list) do
    [
      Constants.DISTRIBUTION.ama_hearing_case_affinity_days,
      Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days,
      Constants.DISTRIBUTION.cavc_aod_affinity_days,
      Constants.DISTRIBUTION.cavc_affinity_days
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

      step "enabled and disabled levers display correctly" do
        # From affinity_days_levers_spec.rb
        option_list = [Constants.ACD_LEVERS.omit, Constants.ACD_LEVERS.infinite, Constants.ACD_LEVERS.value]

        disabled_lever_list.each do |disabled_lever|
          option_list.each do |option|
            expect(find("##{disabled_lever}-#{option}", visible: false)).to be_disabled
          end
        end

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
        clear_field_completely(ama_direct_reviews_field)
        clear_field_completely(alternative_batch_size_field)

        set_field_value_with_delay(ama_direct_reviews_field, "123")
        expect(page).to have_field(ama_direct_reviews_field, with: "123")

        click_cancel_button
        expect(page).to have_field(ama_direct_reviews_field, with: "365")

        set_field_value_with_delay(ama_direct_reviews_field, "123")
        set_field_value_with_delay(alternative_batch_size_field, "12")

        expect(page).to have_field(ama_direct_reviews_field, with: "123")
        expect(page).to have_field(alternative_batch_size_field, with: "12")

        click_cancel_button
        expect(page).to have_field(ama_direct_reviews_field, with: "365")
        expect(page).to have_field(alternative_batch_size_field, with: "15")
      end

      step "cancelling changes on confirm modal returns user to page without resetting the values in the fields" do
        clear_field_completely(ama_direct_reviews_field)
        clear_field_completely(alternative_batch_size_field)

        set_field_value_with_delay(ama_direct_reviews_field, "123")
        set_field_value_with_delay(alternative_batch_size_field, "13")

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
        clear_field_completely(ama_direct_reviews_field)
        clear_field_completely(ama_evidence_submissions_field)

        set_field_value_with_delay(ama_direct_reviews_field, "123")
        set_field_value_with_delay(ama_evidence_submissions_field, "456")
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

        clear_field_completely("#{batch_size_per_attorney}-field")
        clear_field_completely("#{request_more_cases_minimum}-field")
        clear_field_completely("#{alternate_batch_size}-field")

        set_field_value_with_delay("#{alternate_batch_size}-field", "ABC")
        set_field_value_with_delay("#{batch_size_per_attorney}-field", "-1")
        set_field_value_with_delay("#{request_more_cases_minimum}-field", "(*&)")

        expect(page).to have_field("#{alternate_batch_size}-field", with: "")
        expect(page).to have_field("#{batch_size_per_attorney}-field", with: "1")
        expect(page).to have_field("#{request_more_cases_minimum}-field", with: "")

        expect(find("##{alternate_batch_size} > div > div > span")).to have_content(EMPTY_ERROR_MESSAGE)
        expect(find("##{request_more_cases_minimum} > div > div > span")).to have_content(EMPTY_ERROR_MESSAGE)
      end

      step "batch size lever section errors clear with valid inputs" do
        clear_field_completely("#{batch_size_per_attorney}-field")
        clear_field_completely("#{request_more_cases_minimum}-field")
        clear_field_completely("#{alternate_batch_size}-field")

        set_field_value_with_delay("#{alternate_batch_size}-field", "42")
        set_field_value_with_delay("#{batch_size_per_attorney}-field", "32")
        set_field_value_with_delay("#{request_more_cases_minimum}-field", "25")

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

  # Added this method to handle the delay in setting the field value
  # Possibly caused by issue with Chromdirver and Capybara not allowing the field to be cleared before setting the new value
  # Issue causes the field to be set with the previous value and the new value
  # In addition to each individual character needing being sent with a delay
  def set_field_value_with_delay(field_id, value)
    area = find("##{field_id}")
    area.click
    area.native.clear  # Clear the field using the native clear method

    # Send keys with delay
    value.each_char do |char|
      area.send_keys char
      sleep 0.1  # 100 ms delay between keystrokes
    end
  end

  # This method ensures that the field is cleared completely and no lingering values are present
  def clear_field_completely(field)
    max_attempts = 10
    attempts = 0

    while find_field(field).value.present? && attempts < max_attempts
      find_field(field).set("")
      sleep 0.1 # Small delay to allow the field to update
      attempts += 1
    end

    if attempts == max_attempts
      raise "Failed to clear the field after #{max_attempts} attempts"
    end
  end
end
