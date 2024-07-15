# frozen_string_literal: true

RSpec.feature "Admin UI" do
  # TODO: break this out if possible
  before { Seeds::CaseDistributionLevers.new.seed! }

  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:disabled_lever_list) do
    [
      Constants.DISTRIBUTION.cavc_aod_affinity_days,
      Constants.DISTRIBUTION.cavc_affinity_days,
      Constants.DISTRIBUTION.aoj_affinity_days,
      Constants.DISTRIBUTION.aoj_aod_affinity_days,
      Constants.DISTRIBUTION.aoj_cavc_affinity_days
    ]
  end

  let(:enabled_lever_list) do
    [
      Constants.DISTRIBUTION.ama_hearing_case_affinity_days,
      Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days
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

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    let!(:audit_lever_entry_1) do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: ama_direct_reviews_lever,
             previous_value: 10,
             update_value: 15,
             created_at: 5.days.ago)
    end
    let!(:audit_lever_entry_2) do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: alternate_batch_size_lever,
             previous_value: 7,
             update_value: 6,
             created_at: 4.days.ago)
    end
    let!(:audit_lever_entry_3) do
      Timecop.travel(3.days.ago) do
        create(:case_distribution_audit_lever_entry,
               case_distribution_lever: ama_direct_reviews_lever,
               previous_value: 15,
               update_value: 5)
        create(:case_distribution_audit_lever_entry,
               case_distribution_lever: alternate_batch_size_lever,
               previous_value: 2,
               update_value: 4)
      end
    end

    it "the lever control page renders correctly and has no options to change/save values", :aggregate_failures do
      step "page renders" do
        visit "case-distribution-controls"
        confirm_page_and_section_loaded
        expect(page).not_to have_button("Cancel")
        expect(page).not_to have_button("Save")

        disabled_lever_list.each do |item|
          expect(find("#lever-wrapper-#{item}")).to match_css(".lever-disabled")
          expect(find("#affinity-day-label-for-#{item}")).to match_css(".lever-disabled")
        end

        enabled_lever_list.each do |item|
          expect(find("#lever-wrapper-#{item}")).not_to match_css(".lever-disabled")
          expect(find("#affinity-day-label-for-#{item}")).not_to match_css(".lever-disabled")
        end

        expect(find("##{ama_hearings}-lever-value > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_direct_reviews}-lever-value > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_evidence_submissions}-lever-value > span")["data-disabled-in-ui"]).to eq("false")

        expect(find("##{ama_hearings}-lever-toggle > div > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_direct_reviews}-lever-toggle > div > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_evidence_submissions}-lever-toggle > div > span")["data-disabled-in-ui"]).to eq("false")

        expect(find("##{alternate_batch_size} > label")).to match_css(".lever-active")
        expect(find("##{batch_size_per_attorney} > label")).to match_css(".lever-active")
        expect(find("##{request_more_cases_minimum} > label")).to match_css(".lever-active")
      end

      step "lever history displays correctly" do
        expect(find("#lever-history-table-row-0")).to have_content(current_user.css_id)
        expect(find("#lever-history-table-row-0")).to have_content(alternate_batch_size_lever.title)
        expect(find("#lever-history-table-row-0")).to have_content("2 #{alternate_batch_size_lever.unit}")
        expect(find("#lever-history-table-row-0")).to have_content("4 #{alternate_batch_size_lever.unit}")
        expect(find("#lever-history-table-row-0")).to have_content(ama_direct_reviews_lever.title)
        expect(find("#lever-history-table-row-0")).to have_content("15 #{ama_direct_reviews_lever.unit}")
        expect(find("#lever-history-table-row-0")).to have_content("5 #{ama_direct_reviews_lever.unit}")

        expect(find("#lever-history-table-row-1")).to have_content(current_user.css_id)
        expect(find("#lever-history-table-row-1")).to have_content(alternate_batch_size_lever.title)
        expect(find("#lever-history-table-row-1")).to have_content("7 #{alternate_batch_size_lever.unit}")
        expect(find("#lever-history-table-row-1")).to have_content("6 #{alternate_batch_size_lever.unit}")

        expect(find("#lever-history-table-row-2")).to have_content(current_user.css_id)
        expect(find("#lever-history-table-row-2")).to have_content(ama_direct_reviews_lever.title)
        expect(find("#lever-history-table-row-2")).to have_content("10 #{ama_direct_reviews_lever.unit}")
        expect(find("#lever-history-table-row-2")).to have_content("15 #{ama_direct_reviews_lever.unit}")
      end
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    it "the lever control page operates correctly" do
      visit "case-distribution-controls"
      confirm_page_and_section_loaded

      empty_error_message = "Please enter a value greater than or equal to 0"

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

      step "levers initally display correctly" do
        # From ama_np_dist_goals_by_docket_lever_spec.rb
        expect(page).to have_field(ama_hearings_field.to_s, disabled: false)
        expect(page).to have_field(ama_direct_reviews_field.to_s)
        expect(page).to have_field(ama_evidence_submissions_field.to_s, disabled: false)

        expect(page).to have_button("toggle-switch-#{ama_hearings}", disabled: false)
        expect(page).to have_button("toggle-switch-#{ama_direct_reviews}", disabled: false)
        expect(page).to have_button("toggle-switch-#{ama_evidence_submissions}", disabled: false)
      end

      step "inactive levers are displayed with values" do
        # From inactive_data_elements_levers_spec.rb
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

      step "cancelling changes resets values" do
        # Capybara locally is not setting clearing the field prior to entering the new value so fill with ""
        fill_in ama_direct_reviews_field, with: ""

        # From lever_buttons_spec.rb
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
        # From ama_np_dist_goals_by_docket_lever_spec.rb

        fill_in ama_direct_reviews_field, with: "ABC"
        expect(page).to have_field(ama_direct_reviews_field, with: "")
        expect(find("##{ama_direct_reviews_field}-lever")).to have_content(empty_error_message)

        fill_in ama_direct_reviews_field, with: "-1"
        expect(page).to have_field(ama_direct_reviews_field, with: "1")
        expect(find("##{ama_direct_reviews_field}-lever").has_no_content?(empty_error_message)).to eq(true)
      end

      step "time goals section error clears with valid input" do
        # From ../acd_audit_history/audit_lever_history_table_spec.rb
        expect(find("#lever-history-table").has_no_content?("123 days")).to eq(true)
        expect(find("#lever-history-table").has_no_content?("300 days")).to eq(true)

        # Change two levers at once to satisfy lever_buttons_spec.rb
        fill_in ama_direct_reviews_field, with: ""
        fill_in ama_direct_reviews_field, with: "123"
        fill_in ama_evidence_submissions_field, with: "456"
        click_save_button
        click_modal_confirm_button
      end

      step "batch size lever section errors display with invalid inputs" do
        # From batch_size_levers_spec.rb
        expect(page).to have_field("#{alternate_batch_size}-field", readonly: false)
        expect(page).to have_field("#{batch_size_per_attorney}-field", readonly: false)
        expect(page).to have_field("#{request_more_cases_minimum}-field", readonly: false)

        fill_in "#{alternate_batch_size}-field", with: "ABC"
        fill_in "#{batch_size_per_attorney}-field", with: "-1"
        fill_in "#{request_more_cases_minimum}-field", with: "(*&)"

        expect(page).to have_field("#{alternate_batch_size}-field", with: "")
        expect(page).to have_field("#{batch_size_per_attorney}-field", with: "1")
        expect(page).to have_field("#{request_more_cases_minimum}-field", with: "")

        expect(find("##{alternate_batch_size} > div > div > span")).to have_content(empty_error_message)
        expect(find("##{request_more_cases_minimum} > div > div > span")).to have_content(empty_error_message)
      end

      step "batch size lever section errors clear with valid inputs" do
        # From batch_size_levers_spec.rb
        fill_in "#{alternate_batch_size}-field", with: "42"
        fill_in "#{batch_size_per_attorney}-field", with: "32"
        fill_in "#{request_more_cases_minimum}-field", with: "25"

        expect(page).not_to have_content(empty_error_message)
      end

      step "lever history displays on page" do
        # From ../acd_audit_history/audit_lever_history_table_spec.rb
        expect(find("#lever-history-table").has_content?("123 days")).to eq(true)
        expect(find("#lever-history-table").has_no_content?("300 days")).to eq(true)

        fill_in ama_direct_reviews_field, with: "300"
        click_save_button
        click_modal_confirm_button

        expect(find("#lever-history-table").has_content?("123 days")).to eq(true)
        expect(find("#lever-history-table").has_content?("456 days")).to eq(true)
        expect(find("#lever-history-table").has_content?("300 days")).to eq(true)
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def confirm_page_and_section_loaded
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_AFFINITY_DAYS_H2_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_DOCKET_TIME_GOALS_SECTION_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_BATCH_SIZE_H2_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_HISTORY_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_HISTORY_DESCRIPTION)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_STATIC_LEVERS_TITLE)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_hearing_case_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.cavc_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.cavc_aod_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.aoj_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.aoj_aod_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.aoj_cavc_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_hearings_section_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_direct_review_section_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_evidence_submission_section_title)
    expect(page).to have_content(Constants.DISTRIBUTION.alternative_batch_size_title)
    expect(page).to have_content(Constants.DISTRIBUTION.batch_size_per_attorney_title)
    expect(page).to have_content(Constants.DISTRIBUTION.request_more_cases_minimum_title)

    # From inactive_data_elements_levers_spec.rb
    expect(page).to have_content(Constants.DISTRIBUTION.maximum_direct_review_proportion_title)
    expect(page).to have_content(Constants.DISTRIBUTION.minimum_legacy_proportion_title)
    expect(page).to have_content(Constants.DISTRIBUTION.nod_adjustment_title)
    expect(page).to have_content(Constants.DISTRIBUTION.bust_backlog_title)
    expect(find("##{maximum_direct_review_proportion}-description")).to match_css(".description-styling")
    expect(find("##{maximum_direct_review_proportion}-product")).to match_css(".value-styling")
    expect(find("##{minimum_legacy_proportion}-description")).to match_css(".description-styling")
    expect(find("##{minimum_legacy_proportion}-product")).to match_css(".value-styling")
    expect(find("##{nod_adjustment}-description")).to match_css(".description-styling")
    expect(find("##{nod_adjustment}-product")).to match_css(".value-styling")
    expect(find("##{bust_backlog}-description")).to match_css(".description-styling")
    expect(find("##{bust_backlog}-product")).to match_css(".value-styling")
  end
  # rubocop:enable Metrics/AbcSize

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
