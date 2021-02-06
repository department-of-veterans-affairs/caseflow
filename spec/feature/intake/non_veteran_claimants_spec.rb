# frozen_string_literal: true

## This feature spec covers non-veteran claimants for Appeals when they are not listed in the veteran's relationships

feature "Non-veteran claimants", :postgres do
  include IntakeHelpers

  before do
    setup_intake_flags
  end

  let(:veteran_file_number) { "123412345" }
  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end
  let(:benefit_type) { "compensation" }

  context "with non_veteran_claimants feature toggle" do
    before { FeatureToggle.enable!(:non_veteran_claimants) }
    after { FeatureToggle.disable!(:non_veteran_claimants) }

    let(:attorneys) do
      Array.new(15) { create(:bgs_attorney) }
    end

    let(:attorney) { attorneys.last }

    it "allows selecting claimant not listed" do
      start_appeal(veteran)
      visit "/intake"

      expect(page).to have_current_path("/intake/review_request")

      within_fieldset("Is the claimant someone other than the Veteran?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end

      expect(page).to have_selector("label[for=claimant-options_claimant_not_listed]")

      within_fieldset(COPY::SELECT_CLAIMANT_LABEL) do
        find("label", text: "Claimant not listed", match: :prefer_exact).click
      end

      click_intake_continue

      expect(page).to have_current_path("/intake/add_claimant")
      expect(page).to have_content("Add Claimant")

      fill_in("Relationship to the Veteran", with: "Attorney (previously or currently)").send_keys :enter
      add_existing_attorney(attorney)

      expect(page).to have_content("Claimant's address")
      expect(page).to have_content(attorney.name)
      expect(page).to have_content(attorney.address_line_1.titleize)
      expect(page).to have_content("Do you have a VA Form 21-22 for this claimant?")
      expect(page).to have_button("Continue to next step", disabled: true)

      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "No", match: :prefer_exact).click
      end

      expect(page).to have_button("Continue to next step", disabled: false)

      # Verify that this can be removed
      find(".cf-select__clear-indicator").click
      expect(page).to_not have_content(attorney.name)
      expect(page).to_not have_content("Claimant's address")
      expect(page).to have_button("Continue to next step", disabled: true)
      expect(page).to have_content("Type to search...")

      safe_click ".dropdown-listedAttorney"
      fill_in("listedAttorney", with: "Name not listed").send_keys :enter
      select_claimant(0)

      expect(page).to have_content("Is the claimant an organization or individual?")
      expect(page).to have_content("Do you have a VA Form 21-22 for this claimant?")

      # Check validation for unlisted attorney
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Organization", match: :prefer_exact).click
      end
      fill_in "Organization name", with: "Attorney's Law Firm"
      fill_in "Street address 1", with: "1234 Justice St."
      fill_in "City", with: "Anytown"
      fill_in("State", with: "California").send_keys :enter
      fill_in("Zip", with: "12345").send_keys :enter
      fill_in("Country", with: "United States").send_keys :enter
      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "No", match: :prefer_exact).click
      end

      expect(page).to have_button("Continue to next step", disabled: false)

      click_button "Continue to next step"
      expect(page).to have_current_path("/intake/add_issues")
    end

    it "allows selecting claimant not listed goes to and add_power_of_attorney path" do
      start_appeal(veteran)
      visit "/intake"

      expect(page).to have_current_path("/intake/review_request")

      within_fieldset("Is the claimant someone other than the Veteran?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end

      expect(page).to have_selector("label[for=claimant-options_claimant_not_listed]")

      within_fieldset(COPY::SELECT_CLAIMANT_LABEL) do
        find("label", text: "Claimant not listed", match: :prefer_exact).click
      end

      click_intake_continue

      expect(page).to have_current_path("/intake/add_claimant")
      expect(page).to have_content("Add Claimant")

      fill_in("Relationship to the Veteran", with: "Other").send_keys :enter

      expect(page).to have_content("Is the claimant an organization or individual?")

      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Organization", match: :prefer_exact).click
      end
      expect(page).to have_button("Continue to next step", disabled: true)

      # fill in form information
      fill_in "Organization name", with: "Attorney's Law Firm"
      fill_in "Street address 1", with: "1234 Justice St."
      fill_in "City", with: "Anytown"
      fill_in("State", with: "California").send_keys :enter
      fill_in("Zip", with: "12345").send_keys :enter
      fill_in("Country", with: "United States").send_keys :enter
      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end

      expect(page).to have_button("Continue to next step", disabled: false)
      click_button "Continue to next step"
      expect(page).to have_current_path("/intake/add_power_of_attorney")
    end
  end

  def add_existing_attorney(attorney)
    fill_in "Claimant's name", with: attorney.name
    select_claimant(0)
  end

  def select_claimant(index = 0)
    click_dropdown({ index: index }, find(".dropdown-listedAttorney"))
  end
end
