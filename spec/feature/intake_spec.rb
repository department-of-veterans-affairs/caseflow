require "rails_helper"

RSpec.feature "RAMP Intake" do
  before do
    FeatureToggle.enable!(:intake)

    Timecop.freeze(Time.utc(2017, 1, 1))
  end

  let!(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  context "As a user with Mail Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Mail Intake"])
    end

    scenario "Search for a veteran that does not exist in BGS" do
      visit "/intake"
      fill_in "Search small", with: "5678"
      click_on "Search"

      expect(page).to have_current_path("/intake")
      expect(page).to have_content("Veteran ID not found")
    end

    scenario "Search for a veteran that has not received a RAMP election" do
      visit "/intake"
      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake")
      expect(page).to have_content("No opt-in letter was sent to this veteran")
    end

    scenario "Search for a veteran that has received a RAMP election" do
      visit "/intake"
      RampElection.create!(veteran_file_number: "12341234", notice_date: 5.days.ago)

      visit "/intake"
      fill_in "Search small", with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/review-request")
      expect(page).to have_content("Review Ed Merica's opt-in request")

      intake = RampIntake.find_by(veteran_file_number: "12341234")
      expect(intake).to_not be_nil
      expect(intake.started_at).to eq(Time.zone.now)
      expect(intake.user).to eq(current_user)
    end

    scenario "Review RAMP Election form" do
      election = RampElection.create!(veteran_file_number: "12341234", notice_date: 5.days.ago)
      RampIntake.new(veteran_file_number: "12341234", user: current_user).start!

      visit "/intake/review-request"

      within_fieldset("Which election did the Veteran select?") do
        find("label", text: "Supplemental Claim").click
      end
      fill_in "What is the Receipt Date for this election form?", with: "08/09/2017"

      click_on "Continue to next step"
      expect(page).to have_content("Finish processing Supplemental Claim request")

      expect(election.reload.option_selected).to eq("supplemental_claim")
      expect(election.receipt_date).to eq(Date.new(2017, 8, 9))
    end
  end

  context "As a user without Mail Intake role" do
    let!(:current_user) do
      User.authenticate!(roles: ["Not Mail Intake"])
    end

    scenario "Attempts to view establish claim pages" do
      visit "/intake"
      expect(page).to have_content("You aren't authorized")
    end
  end
end
