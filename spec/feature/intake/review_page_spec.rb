# frozen_string_literal: true

feature "Intake Review Page", :postgres do
  include IntakeHelpers

  before do
    setup_intake_flags
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end
  let(:benefit_type) { "compensation" }

  describe "Validating receipt date not blank or before AMA" do
    before { FeatureToggle.enable!(:use_ama_activation_date) }

    it "shows correct error with blank or pre-AMA dates" do
      start_higher_level_review(veteran, receipt_date: nil)
      visit "/intake"
      expect(page).to have_current_path("/intake/review_request")
      click_intake_continue

      expect(page).to have_content("Please enter a valid receipt date.")
      fill_in "What is the Receipt Date of this form?", with: "01/01/2019"
      click_intake_continue

      expect(page).to have_content("Receipt Date cannot be prior to 02/19/2019.")
    end
  end

  describe "Validating receipt date not blank or before AMA when claimant not listed" do
    before do
      FeatureToggle.enable!(:use_ama_activation_date)
      FeatureToggle.enable!(:non_veteran_claimants)
    end
    after do
      FeatureToggle.disable!(:use_ama_activation_date)
      FeatureToggle.disable!(:non_veteran_claimants)
    end
    it "shows correct error with blank or pre-AMA dates" do
      start_appeal(veteran, receipt_date: nil)
      visit "/intake"
      expect(page).to have_current_path("/intake/review_request")
      click_intake_continue

      fill_in "What is the Receipt Date of this form?", with: "01/01/2019"
      within_fieldset("Is the claimant someone other than the Veteran?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end
      find("label", text: "Claimant not listed", match: :prefer_exact).click
      click_intake_continue

      expect(page).to have_current_path("/intake/review_request")
      expect(page).to have_content("Receipt Date cannot be prior to 02/19/2019")
    end
  end

  context "when the Veteran is not valid" do
    let!(:veteran) do
      Generators::Veteran.build(
        file_number: "25252525",
        sex: nil,
        ssn: nil,
        country: nil,
        address_line1: "this address is more than 20 chars"
      )
    end

    scenario "Higher level review shows alert on Review page" do
      check_invalid_veteran_alert_on_review_page(Constants.INTAKE_FORM_NAMES.higher_level_review)
    end

    scenario "Supplemental Claim shows alert on Review page" do
      check_invalid_veteran_alert_on_review_page(Constants.INTAKE_FORM_NAMES.supplemental_claim)
    end
  end

  describe "Selecting a claimant" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        [
          { first_name: "BOB",
            last_name: "VANCE",
            ptcpnt_id: "5382910292",
            relationship_type: "Spouse" },
          { first_name: "BILLY",
            last_name: "VANCE",
            ptcpnt_id: "12345",
            relationship_type: "Child" },
          { first_name: "BLAKE",
            last_name: "VANCE",
            ptcpnt_id: "11111",
            relationship_type: "Other" }
        ]
      )
    end

    context "when the user goes back and edits the claimant" do
      describe "given an appeal" do
        it "only saves one claimant" do
          review = start_appeal(veteran).first

          check_edited_claimant(review)
        end
      end

      [:higher_level_review, :supplemental_claim].each do |claim_review_type|
        describe "given a #{claim_review_type}" do
          it "only saves one claimant" do
            review = start_claim_review(claim_review_type, veteran: veteran).first

            check_edited_claimant(review)
          end
        end
      end
    end

    context "when veteran is deceased" do
      # before do
      #   allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return([])
      # end
      let(:veteran) do
        create(:veteran, file_number: "123121234", date_of_death: 1.month.ago)
      end
      let(:intake) { create(:intake, veteran_file_number: veteran.file_number, user: current_user, detail: detail) }
      let(:receipt_date) { 2.months.ago }
      let(:decision_date) { 3.months.ago.mdY }

      context "on an appeal" do
        let(:detail) do
          create(
            :appeal,
            veteran_file_number: veteran.file_number,
            receipt_date: receipt_date,
            docket_type: Constants.AMA_DOCKETS.evidence_submission,
            legacy_opt_in_approved: false
          )
        end

        it "disables letting the veteran claimant option" do
          check_deceased_veteran_claimant(intake)
        end

        context "when the deceased appellants toggle is enabled" do
          before { FeatureToggle.enable!(:deceased_appellants) }
          after { FeatureToggle.disable!(:deceased_appellants) }

          scenario "veteran can be claimant" do
            check_deceased_veteran_claimant(intake)
          end
        end
      end

      context "higher level review" do
        let(:detail) do
          create(
            :higher_level_review,
            veteran_file_number: veteran.file_number,
            receipt_date: receipt_date,
            informal_conference: false,
            legacy_opt_in_approved: false,
            same_office: false
          )
        end

        scenario "do not show veteran as a valid payee code" do
          start_higher_level_review(veteran)
          check_deceased_veteran_cant_be_payee
        end

        it "disables letting the veteran claimant option" do
          check_deceased_veteran_claimant(intake)
        end

        context "when the deceased appellants toggle is enabled" do
          before { FeatureToggle.enable!(:deceased_appellants) }
          after { FeatureToggle.disable!(:deceased_appellants) }

          scenario "veteran can still not be claimant" do
            check_deceased_veteran_claimant(intake)
          end
        end
      end

      context "supplemental claim" do
        let(:detail) do
          create(
            :supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: receipt_date,
            legacy_opt_in_approved: false
          )
        end

        scenario "do not show veteran as a valid payee code" do
          start_supplemental_claim(veteran)
          check_deceased_veteran_cant_be_payee
        end

        it "disables letting the veteran claimant option" do
          check_deceased_veteran_claimant(intake)
        end

        context "when the deceased appellants toggle is enabled" do
          before { FeatureToggle.enable!(:deceased_appellants) }
          after { FeatureToggle.disable!(:deceased_appellants) }

          scenario "veteran can still not be claimant" do
            check_deceased_veteran_claimant(intake)
          end
        end
      end
    end

    context "when the Veteran is not the claimant" do
      let(:claim_participant_id) { "20678356" }
      let!(:recent_end_product_with_claimant) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "claim_id",
            claimant_first_name: "BOB",
            claimant_last_name: "VANCE",
            payee_type_code: "11",
            claim_date: 5.days.ago
          }
        )
      end

      let!(:outdated_end_product_with_claimant) do
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: {
            benefit_claim_id: "another_claim_id",
            claimant_first_name: "BOB",
            claimant_last_name: "VANCE",
            payee_type_code: "10",
            claim_date: 10.days.ago
          }
        )
      end

      context "when the claimant is missing an address" do
        let(:error_text) { "Please supply the claimant's address in VBMS" }
        before do
          allow_any_instance_of(BgsAddressService).to receive(:fetch_bgs_record).and_return(nil)
        end

        describe "given an appeal" do
          it "does not require the claimant to have an address" do
            review = start_appeal(veteran, claim_participant_id: claim_participant_id).first

            check_claimant_address_error(review, benefit_type, error_text)
          end
        end

        [:higher_level_review, :supplemental_claim].each do |claim_review_type|
          describe "given a #{claim_review_type}" do
            it "requires that the claimant have an address" do
              review = start_claim_review(
                claim_review_type,
                veteran: veteran,
                claim_participant_id: claim_participant_id,
                no_claimant: true
              ).first

              check_claimant_address_error(review, benefit_type, error_text)
            end
          end
        end

        context "for a noncompensation benefit_type" do
          let(:benefit_type) { "education" }

          [:higher_level_review, :supplemental_claim].each do |claim_review_type|
            describe "given a #{claim_review_type}" do
              it "does not require that the claimant have an address" do
                review = start_claim_review(
                  claim_review_type,
                  veteran: veteran,
                  claim_participant_id: claim_participant_id,
                  benefit_type: benefit_type
                ).first

                check_claimant_address_error(review, benefit_type, error_text)
              end
            end
          end
        end
      end

      context "when the claimant has an invalid address" do
        let(:invalid_address) { { address_line_1: "one", address_line_2: "two  ", city: nil, state: nil, zip: nil } }
        let(:error_text) { "Please update the claimant's address in VBMS to be valid" }
        before do
          allow_any_instance_of(BgsAddressService).to receive(:fetch_bgs_record).and_return(invalid_address)
        end

        [:higher_level_review, :supplemental_claim].each do |claim_review_type|
          describe "given a #{claim_review_type}" do
            it "requires that the claimant have a valid address" do
              review = start_claim_review(
                claim_review_type,
                veteran: veteran,
                claim_participant_id: claim_participant_id,
                no_claimant: true
              ).first

              check_claimant_address_error(review, benefit_type, error_text)
            end
          end
        end
      end

      context "when benefit type is pension or compensation" do
        [:higher_level_review, :supplemental_claim].each do |claim_review_type|
          describe "given a #{claim_review_type}" do
            it "requires payee code and shows default value" do
              start_claim_review(claim_review_type, veteran: veteran, claim_participant_id: claim_participant_id)
              check_pension_and_compensation_payee_code
            end
          end
        end
      end

      context "when there are no relationships" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return([])
        end

        context "higher level review" do
          it "shows message and does not allow user to continue" do
            start_higher_level_review(
              veteran,
              benefit_type: benefit_type,
              no_claimant: true
            )

            check_no_relationships_behavior
          end
        end

        context "supplemental claim" do
          it "shows message and does not allow user to continue" do
            start_supplemental_claim(
              veteran,
              benefit_type: benefit_type,
              no_claimant: true
            )
            check_no_relationships_behavior
          end
        end
      end

      context "when adding a new attorney claimant" do
        let(:attorneys) do
          Array.new(15) { create(:bgs_attorney) }
        end

        it "doesn't allow adding new claimants" do
          start_appeal(veteran, claim_participant_id: claim_participant_id)

          visit "/intake"

          expect(page).to have_current_path("/intake/review_request")

          within_fieldset("Is the claimant someone other than the Veteran?") do
            find("label", text: "Yes", match: :prefer_exact).click
          end

          expect(page).to_not have_content("+ Add Claimant")
        end

        context "establish_fiduciary_eps feature toggle" do
          before { FeatureToggle.enable!(:establish_fiduciary_eps) }
          after { FeatureToggle.disable!(:establish_fiduciary_eps) }

          let(:benefit_type) { "fiduciary" }
          let(:nonrating_date) { Time.zone.yesterday }

          scenario "when fiduciary is enabled" do
            start_supplemental_claim(
              veteran,
              benefit_type: benefit_type,
              claim_participant_id: claim_participant_id
            )

            visit "/intake"

            expect(page).to have_current_path("/intake/review_request")

            within_fieldset("Is the claimant someone other than the Veteran?") do
              find("label", text: "Yes", match: :prefer_exact).click
            end

            expect(page).to have_content("What is the payee code for this claimant?")
            find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click
            expect(find(".cf-select__value-container")).to have_content("11 - C&P First Child")
            click_intake_continue

            expect(page).to have_content("Bob Vance, Spouse (payee code 11)")
            click_button("+ Add issue")

            expect(page).to have_content("Does issue 1 match any of these non-rating issue categories?")
            add_intake_nonrating_issue(
              category: "Appointment of a Fiduciary",
              description: "Description for A Fiduciary",
              date: nonrating_date.mdY
            )

            expect(page).to have_content("Appointment of a Fiduciary (38 CFR 13.100)")
            click_on "Establish EP"

            expect(page).to have_content("Contention: Appointment of a Fiduciary")
            fiduciary_end_product = EndProductEstablishment.where(
              code: "040SCRFID",
              modifier: "040",
              payee_code: "11",
              source_type: "SupplementalClaim"
            )
            expect(fiduciary_end_product).to_not be_nil
          end
        end

        def add_existing_attorney(attorney)
          click_button("+ Add Claimant")
          expect(page).to have_selector("#add_claimant_modal")
          expect(page).to have_button("Add this claimant", disabled: true)
          claimant_search(attorney.name)
          select_claimant(0)
          expect(page).to have_button("Add this claimant", disabled: false)
          click_button "Add this claimant"
          expect(page).to_not have_selector("#add_claimant_modal")
          expect(page).to have_content("#{attorney.name}, Attorney")
        end

        # rubocop: disable Metrics/AbcSize
        def add_unlisted_claimant(notes)
          click_button("+ Add Claimant")
          expect(page).to have_content("Claimant not listed")
          expect(page).to have_button("Add this claimant", disabled: true)
          find("label[for=notListed]").click
          expect(page).to have_content("Notes e.g.")
          expect(page).to have_button("Add this claimant", disabled: true)

          fill_in "Notes e.g.", with: notes
          expect(page).to have_button("Add this claimant", disabled: false)
          click_button "Add this claimant"
          expect(page).to_not have_selector("#add_claimant_modal")
          expect(page).to have_content("Claimant not listed, Attorney")
          expect(page).to have_content(notes)
          # unlisted claimant has empty ID for radio value
          expect(find("input", id: "claimant-options_", visible: false).checked?).to eq(true)
        end
        # rubocop: enable Metrics/AbcSize

        def claimant_search(search)
          find(".dropdown-claimant").fill_in "claimant", with: search
        end

        def select_claimant(index = 0)
          click_dropdown({ index: index }, find(".dropdown-claimant"))
        end
      end
    end
  end
end

def check_no_relationships_behavior
  # first start the review
  visit "/intake"
  within_fieldset("Is the claimant someone other than the Veteran?") do
    find("label", text: "Yes", match: :prefer_exact).click
  end
  expect(page).to have_content("This Veteran currently has no known relationships.")
  expect(page).to have_button("Continue to next step", disabled: true)
  expect(page).to_not have_content("What is the payee code for this claimant?")
end

def check_deceased_veteran_claimant(intake)
  visit "/intake"

  allow_deceased_appellants = intake.detail.is_a?(Appeal) && FeatureToggle.enabled?(:deceased_appellants)
  if allow_deceased_appellants
    # ability to select veteran claimant is enabled
    expect(page).to have_css("input[id=different-claimant-option_false]", visible: false)
    expect(page).to_not have_content(COPY::DECEASED_CLAIMANT_TITLE)

    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "No", match: :prefer_exact).click
    end

    expect(page).to have_content(COPY::DECEASED_CLAIMANT_TITLE)
  else
    # ability to select veteran claimant is disabled
    expect(page).to have_css("input[disabled][id=different-claimant-option_false]", visible: false)
    expect(page).to_not have_content(COPY::DECEASED_CLAIMANT_TITLE)

    find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click
  end

  click_intake_continue

  expect(page).to have_content("Add Issues")

  click_intake_add_issue
  add_intake_nonrating_issue(date: decision_date)
  click_intake_finish

  expect(page).to have_current_path("/intake/completed")

  if allow_deceased_appellants
    expect(page).to have_content(COPY::DECEASED_CLAIMANT_TITLE)
  else
    expect(page).to_not have_content(COPY::DECEASED_CLAIMANT_TITLE)
  end
end

def check_deceased_veteran_cant_be_payee
  visit "/intake"

  # click on payee code dropdown
  find(".cf-select__control").click

  # verify that veteran cannot be selected
  expect(page.has_no_content?("00 - Veteran")).to eq(true)
  expect(page).to have_content("10 - Spouse")

  find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click
  expect(find(".cf-select__value-container")).to have_content("10 - Spouse")
end

# rubocop: disable Metrics/AbcSize
def check_pension_and_compensation_payee_code
  visit "/intake"
  expect(page).to have_current_path("/intake/review_request")

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Compensation", match: :prefer_exact).click
  end

  fill_in "What is the Receipt Date of this form?", with: Time.zone.tomorrow.mdY
  find("label", text: "Blake Vance, Other", match: :prefer_exact).click
  click_intake_continue

  # check that other validation still works
  expect(page).to have_content(
    "Receipt date cannot be in the future."
  )

  fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY

  click_intake_continue

  expect(page).to have_content("Please select an option.")

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Pension", match: :prefer_exact).click
  end

  click_intake_continue

  expect(page).to have_content("Please select an option.")

  expect(find(".cf-select__placeholder")).to have_content("Select")

  find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click

  expect(find(".cf-select__value-container")).to have_content("11 - C&P First Child")

  fill_in "What is the payee code for this claimant?", with: "10 - Spouse"
  find("#cf-payee-code").send_keys :enter

  click_intake_continue
  expect(page).to have_current_path("/intake/add_issues")
end

def check_claimant_address_error(review, benefit_type, error_text)
  visit "/intake"
  expect(page).to have_current_path("/intake/review_request")

  if review.is_a?(ClaimReview)
    within_fieldset("What is the Benefit Type?") do
      find("label", text: benefit_type.capitalize, match: :prefer_exact).click
    end
  end

  fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY
  find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click

  click_intake_continue

  if review.processed_in_caseflow?
    expect(page).to_not have_content(error_text)
    expect(page).to have_current_path("/intake/add_issues")
  else
    expect(page).to have_content(error_text)
  end
end

def check_edited_claimant(review)
  visit "/intake"
  click_intake_continue

  expect(page).to have_current_path("/intake/add_issues")
  expect(review.claimant.participant_id).to eq(veteran.participant_id)

  page.go_back
  within_fieldset("Is the claimant someone other than the Veteran?") do
    find("label", text: "Yes", match: :prefer_exact).click
  end
  find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click
  fill_in "What is the payee code for this claimant?", with: "10 - Spouse" unless review.is_a?(Appeal)
  click_intake_continue

  expect(page).to have_current_path("/intake/add_issues")
  expect(review.reload.veteran_is_not_claimant).to be true
  expect(review.claimants.count).to eq 1
  expect(review.claimant.participant_id).to eq("5382910292")
end

def check_invalid_veteran_alert_on_review_page(form_type)
  visit "/intake"
  select_form(form_type)
  safe_click ".cf-submit.usa-button"
  fill_in search_bar_title, with: "25252525"
  click_on "Search"

  expect(page).to have_current_path("/intake/review_request")
  expect(page).to_not have_content("Check the Veteran's profile for invalid information")

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Compensation", match: :prefer_exact).click
  end

  expect(page).to have_content("Check the Veteran's profile for invalid information")
  expect(page).to have_content("Please fill in the following fields in the Veteran's profile in VBMS or")
  expect(page).to have_content(
    "the corporate database, then retry establishing the EP in Caseflow: country."
  )
  expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
  expect(page).to have_button("Continue to next step", disabled: true)

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Education", match: :prefer_exact).click
  end

  expect(page).to_not have_content("Check the Veteran's profile for invalid information")
  expect(page).to have_button("Continue to next step", disabled: false)
end

# rubocop: enable Metrics/AbcSize
