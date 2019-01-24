require "support/intake_helpers"

feature "Intake Review Page" do
  include IntakeHelpers

  before do
    setup_intake_flags
  end

  after do
    teardown_intake_flags
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
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
            relationship_type: "Child" }
        ]
      )
    end

    context "when veteran is deceased" do
      let(:veteran) do
        Generators::Veteran.build(file_number: "123121234", date_of_death: Date.new(2017, 11, 20))
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

      context "when benefit type is pension" do
        let(:benefit_type) { "pension" }
        context "higher level review" do
          it "requires payee code" do
          end
        end

        context "supplemental claim" do
          it "requires payee code" do
          end
        end
      end

      context "when there are no relationships" do
        let(:benefit_type) { "compensation" }
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

# rubocop: disable Metrics/MethodLength
# rubocop: disable Metrics/AbcSize
def check_pension_and_compensation_payee_code
  visit "/intake"
  expect(page).to have_current_path("/intake/review_request")

  within_fieldset("What is the Benefit Type?") do
    find("label", text: "Compensation", match: :prefer_exact).click
  end

  fill_in "What is the Receipt Date of this form?", with: "04/20/2025"
  find("label", text: "Billy Vance, Child", match: :prefer_exact).click
  click_intake_continue

  # check that other validation still works
  expect(page).to have_content(
    "Receipt date cannot be in the future."
  )
  expect(page).to have_content("Please select an option.")

  fill_in "What is the Receipt Date of this form?", with: "04/20/2018"

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
# rubocop: enable Metrics/MethodLength
# rubocop: enable Metrics/AbcSize
