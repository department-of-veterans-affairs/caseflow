require "rails_helper"
require "support/intake_helpers"

RSpec.feature "Intake Review Page" do
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
    context "when the Veteran is not the claimant" do
      let(:veteran_is_not_claimant) { true }

      context "when benefit type is pension or compensation" do
        let(:benefit_type) { "compensation" }

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

          context "supplemental claim" do
            it "shows message and does not allow user to continue" do
              start_appeal(
                veteran,
                benefit_type: benefit_type,
                veteran_is_not_claimant: veteran_is_not_claimant
              )
              check_no_relationships_behavior
            end
          end
        end
      end
    end
  end
end

def check_no_relationships_behavior
  # first start the review
  visit "/intake"
  expect(page).to have_content("The Veteran has no relationships in our records")
  expect(page).to have_button("Continue to next step", disabled: true)
  expect(page).to_not have_content("What is the payee code for this claimant?")
end
