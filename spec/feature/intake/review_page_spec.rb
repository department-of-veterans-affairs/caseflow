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

  describe "Validating receipt date not before ama" do
    before { FeatureToggle.enable!(:use_ama_activation_date) }

    it "shows correct error with AMA date" do
      start_higher_level_review(veteran)
      visit "/intake"
      expect(page).to have_current_path("/intake/review_request")
      fill_in "What is the Receipt Date of this form?", with: "01/01/2019"
      click_intake_continue

      expect(page).to have_content(
        "Receipt Date cannot be prior to 02/19/2019."
      )
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
      let(:veteran_is_not_claimant) { false }

      describe "given an appeal" do
        it "only saves one claimant" do
          review = start_appeal(veteran, veteran_is_not_claimant: veteran_is_not_claimant).first

          check_edited_claimant(review)
        end
      end

      [:higher_level_review, :supplemental_claim].each do |claim_review_type|
        describe "given a #{claim_review_type}" do
          it "only saves one claimant" do
            review = start_claim_review(
              claim_review_type,
              veteran: veteran,
              veteran_is_not_claimant: veteran_is_not_claimant
            ).first

            check_edited_claimant(review)
          end
        end
      end
    end

    context "when veteran is deceased" do
      let(:veteran) do
        Generators::Veteran.build(file_number: "123121234", date_of_death: 2.years.ago)
      end

      context "higher level review" do
        scenario "do not show veteran as a valid payee code" do
          start_higher_level_review(veteran)
          check_deceased_veteran_cant_be_payee
        end
      end

      context "supplemental claim" do
        scenario "do not show veteran as a valid payee code" do
          start_supplemental_claim(veteran)
          check_deceased_veteran_cant_be_payee
        end
      end
    end

    context "when the Veteran is not the claimant" do
      let(:veteran_is_not_claimant) { true }
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
        before do
          allow_any_instance_of(BgsAddressService).to receive(:fetch_bgs_record).and_return(nil)
        end

        describe "given an appeal" do
          it "does not require the claimant to have an address" do
            review = start_appeal(veteran, veteran_is_not_claimant: veteran_is_not_claimant).first

            check_claimant_address_error(review, benefit_type)
          end
        end

        [:higher_level_review, :supplemental_claim].each do |claim_review_type|
          describe "given a #{claim_review_type}" do
            it "requires that the claimant have an address" do
              review = start_claim_review(
                claim_review_type,
                veteran: veteran,
                veteran_is_not_claimant: veteran_is_not_claimant
              ).first

              check_claimant_address_error(review, benefit_type)
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
                  veteran_is_not_claimant: veteran_is_not_claimant,
                  benefit_type: benefit_type
                ).first

                check_claimant_address_error(review, benefit_type)
              end
            end
          end
        end
      end

      context "when benefit type is pension or compensation" do
        [:higher_level_review, :supplemental_claim].each do |claim_review_type|
          describe "given a #{claim_review_type}" do
            it "requires payee code and shows default value" do
              start_claim_review(claim_review_type, veteran: veteran, veteran_is_not_claimant: veteran_is_not_claimant)
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
              veteran_is_not_claimant: veteran_is_not_claimant
            )
            check_no_relationships_behavior
          end
        end

        context "supplemental claim" do
          it "shows message and does not allow user to continue" do
            start_supplemental_claim(
              veteran,
              benefit_type: benefit_type,
              veteran_is_not_claimant: veteran_is_not_claimant
            )
            check_no_relationships_behavior
          end
        end

        context "appeal" do
          it "shows message and does not allow user to continue" do
            start_appeal(
              veteran,
              veteran_is_not_claimant: veteran_is_not_claimant
            )
            check_no_relationships_behavior
          end
        end
      end
    end
  end
end

def check_no_relationships_behavior
  # first start the review
  visit "/intake"
  expect(page).to have_content("This Veteran currently has no known relationships.")
  expect(page).to have_button("Continue to next step", disabled: true)
  expect(page).to_not have_content("What is the payee code for this claimant?")
end

def check_deceased_veteran_cant_be_payee
  visit "/intake"

  within_fieldset("Is the claimant someone other than the Veteran?") do
    find("label", text: "Yes", match: :prefer_exact).click
  end

  # click on payee code dropdown
  find(".Select-control").click

  # verify that veteran cannot be selected
  expect(page).not_to have_content("00 - Veteran")
  expect(page).to have_content("10 - Spouse")
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
  expect(page).to have_content("Please select an option.")

  fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Pension", match: :prefer_exact).click
  end

  click_intake_continue

  expect(page).to have_content("Please select an option.")

  expect(find(".Select-placeholder")).to have_content("Select")

  find("label", text: "Bob Vance, Spouse", match: :prefer_exact).click

  expect(find(".Select-multi-value-wrapper")).to have_content("11 - C&P First Child")

  fill_in "What is the payee code for this claimant?", with: "10 - Spouse"
  find("#cf-payee-code").send_keys :enter

  click_intake_continue
  expect(page).to have_current_path("/intake/add_issues")
end

def check_claimant_address_error(review, benefit_type)
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
    expect(page).to_not have_content("Please update the claimant's address")
    expect(page).to have_current_path("/intake/add_issues")
  else
    expect(page).to have_content("Please update the claimant's address")
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
  expect(page).to_not have_content("The Veteran's profile has missing or invalid information")

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Compensation", match: :prefer_exact).click
  end

  expect(page).to have_content("The Veteran's profile has missing or invalid information")
  expect(page).to have_content("Please fill in the following field(s) in the Veteran's profile in VBMS or")
  expect(page).to have_content(
    "the corporate database, then retry establishing the EP in Caseflow: country."
  )
  expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
  expect(page).to have_button("Continue to next step", disabled: true)

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Education", match: :prefer_exact).click
  end

  expect(page).to_not have_content("The Veteran's profile has missing or invalid information")
  expect(page).to have_button("Continue to next step", disabled: false)
end

# rubocop: enable Metrics/AbcSize
