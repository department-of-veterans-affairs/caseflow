# frozen_string_literal: true

feature "Higher-Level Review", :all_dbs do
  include IntakeHelpers

  let(:veteran_file_number) { "123412345" }

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end
  let(:veteran_no_ratings) do
    Generators::Veteran.build(file_number: "55555555",
                              first_name: "Nora",
                              last_name: "Attings",
                              participant_id: "44444444")
  end

  let(:receipt_date) { Time.zone.today - 5.days }

  before do
    Timecop.freeze(post_ama_start_date)
    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
    FeatureToggle.enable!(:filed_by_va_gov_hlr)
    FeatureToggle.enable!(:updated_intake_forms)
  end
  after do
    FeatureToggle.disable!(:filed_by_va_gov_hlr)
    FeatureToggle.disable!(:updated_intake_forms)
  end

  # Specific shared context
  let(:new_individual_claimant) do
    {
      first_name: "Michelle",
      last_name: "McClaimant",
      address1: "123 Main St",
      city: "San Francisco",
      state: "CA",
      zip: "94123",
      country: "United States",
      email: "claimant@example.com"
    }
  end

  let(:new_organizational_claimant) do
    {
      organization_name: "Claimant Inc",
      address1: "123 Main St",
      city: "San Francisco",
      state: "CA",
      zip: "94123",
      country: "United States",
      email: "claimant@example.com"
    }
  end

  let(:other_claimant_type) do
    "Other"
  end

  let(:healthcare_provider_claimant_type) do
    "Healthcare Provider"
  end

  let(:child_provider_claimant_type) do
    "Child"
  end

  let(:spouse_provider_claimant_type) do
    "Spouse"
  end

  let(:attorney_claimant_type) do
    "Attorney (previously or currently)"
  end

  let(:relationship_dropdown_options) do
    [
      "Attorney (previously or currently)", "Child", "Spouse", "Healthcare Provider", "Other"
    ]
  end

  # TODO: move this to intake helpers
  def click_claimant_not_listed
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset(COPY::SELECT_CLAIMANT_LABEL) do
      find("label", text: "Claimant not listed", match: :prefer_exact).click
    end
  end

  # TODO: move this to intake helpers
  def add_new_individual_claimant
    fill_in "First name", with: new_individual_claimant[:first_name]
    fill_in "Last name", with: new_individual_claimant[:last_name]
    fill_in "Street address 1", with: new_individual_claimant[:address1]
    fill_in "City", with: new_individual_claimant[:city]
    fill_in("State", with: new_individual_claimant[:state]).send_keys :enter
    fill_in("Zip", with: new_individual_claimant[:zip]).send_keys :enter
    fill_in("Country", with: new_individual_claimant[:country]).send_keys :enter
    fill_in "Claimant email", with: new_individual_claimant[:email]
  end

  def add_new_organization_claimant
    fill_in "Organization name", with: new_organizational_claimant[:organization_name]
    fill_in "Street address 1", with: new_organizational_claimant[:address1]
    fill_in "City", with: new_organizational_claimant[:city]
    fill_in("State", with: new_organizational_claimant[:state]).send_keys :enter
    fill_in("Zip", with: new_organizational_claimant[:zip]).send_keys :enter
    fill_in("Country", with: new_organizational_claimant[:country]).send_keys :enter
    fill_in "Claimant email", with: new_organizational_claimant[:email]
  end

  def start_intake
    intake_type
  end

  def unlisted_claimant_with_party_type(is_organization = true)
    expect(page).to have_content("Is the claimant an organization or individual?")
    party_type = is_organization ? "Organization" : "Individual"
    within_fieldset("Is the claimant an organization or individual?") do
      find("label", text: party_type, match: :prefer_exact).click
    end
  end

  def select_organization_party_type
    unlisted_claimant_with_party_type true
  end

  def select_individual_party_type
    unlisted_claimant_with_party_type false
  end

  def click_has_va_form(option_text = "Yes")
    within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
      find("label", text: option_text, match: :prefer_exact).click
    end
  end

  def click_does_not_have_va_form(option_text = "No")
    click_has_va_form(option_text)
  end

  def verify_individual_claimant_on_add_issues
    expect(page).to have_content("Add / Remove Issues")
    claimant_name = "#{new_individual_claimant[:first_name]} #{new_individual_claimant[:last_name]}"
    claimant_string = "#{claimant_name}, #{claimant_type}"
    expect(page).to have_content(claimant_string)
  end

  def verify_organizational_claimant_on_add_issues
    expect(page).to have_content("Add / Remove Issues")
    claimant_string = "#{new_organizational_claimant[:organization_name]}, #{claimant_type}"
    expect(page).to have_content(claimant_string)
  end

  shared_examples "HLR/SC intake unlisted claimant" do
    scenario "creating a HLR/SC intake with an unlisted claimant - verify dropdown relationship options" do
      start_intake
      visit "/intake/"
      click_claimant_not_listed

      click_intake_continue

      # Check that we are on the add claimant page
      expect(page).to have_content("Add Claimant")

      # Open the searchable dropdown to view the options
      find(".cf-select__control", text: "Select...").click
      page_options = all("div.cf-select__option")
      page_options_text = page_options.map(&:text)

      # Verify that all of the options are in the dropdown
      expect(page_options_text).to eq(relationship_dropdown_options)
    end

    context("other unlisted claimant") do
      let(:claimant_type) do
        other_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship other with type individual" do
        start_intake
        visit "/intake/"
        click_claimant_not_listed

        click_intake_continue
        # Select other from the dropdown
        fill_in("Relationship to the Veteran", with: other_claimant_type).send_keys :enter
        select_individual_party_type
        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review climant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship other with type organization" do
        start_intake
        visit "/intake/"
        click_claimant_not_listed

        click_intake_continue

        # Select other from the dropdown
        fill_in("Relationship to the Veteran", with: other_claimant_type).send_keys :enter

        select_organization_party_type
        add_new_organization_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review climant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_organizational_claimant_on_add_issues
      end
    end

    context("healthcare provider unlisted claimant") do
      let(:claimant_type) do
        healthcare_provider_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant " \
        "with relationship Healthcare Provider with type individual" do
        start_intake
        visit "/intake/"
        click_claimant_not_listed

        click_intake_continue
        # Select other from the dropdown
        fill_in("Relationship to the Veteran", with: claimant_type).send_keys :enter
        select_individual_party_type
        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review climant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship " \
        "healthcare provider with type organization" do
        start_intake
        visit "/intake/"
        click_claimant_not_listed

        click_intake_continue
        # Select other from the dropdown
        fill_in("Relationship to the Veteran", with: claimant_type).send_keys :enter
        select_organization_party_type
        add_new_organization_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review climant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_organizational_claimant_on_add_issues
      end
    end

    context("child provider unlisted claimant") do
      let(:claimant_type) do
        child_provider_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship Child" do
        start_intake
        visit "/intake/"
        click_claimant_not_listed

        click_intake_continue
        # Select other from the dropdown
        fill_in("Relationship to the Veteran", with: claimant_type).send_keys :enter

        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review climant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end
    end

    context("spouse provider unlisted claimant") do
      let(:claimant_type) do
        spouse_provider_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship Spouse" do
        start_intake
        visit "/intake/"
        click_claimant_not_listed

        click_intake_continue
        # Select other from the dropdown
        fill_in("Relationship to the Veteran", with: claimant_type).send_keys :enter

        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review climant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end
    end

    scenario "creating a HLR/SC intake with an unlisted individual claimant has the appropriate required form fields" do
      start_intake
      visit "/intake/"
      click_claimant_not_listed

      click_intake_continue
      # Select other from the dropdown
      fill_in("Relationship to the Veteran", with: spouse_provider_claimant_type).send_keys :enter

      continue_button = find("button", text: "Continue to next step")
      expect(continue_button[:disabled]).to eq "true"

      fill_in "First name", with: new_individual_claimant[:first_name]
      expect(continue_button[:disabled]).to eq "true"
      fill_in "Last name", with: new_individual_claimant[:last_name]
      expect(continue_button[:disabled]).to eq "true"

      click_does_not_have_va_form

      expect(continue_button[:disabled]).to eq "false"

      # reload the page and change the relationship child to check the required fields
      visit "/intake/add_claimant"
      continue_button = find("button", text: "Continue to next step")
      fill_in("Relationship to the Veteran", with: child_provider_claimant_type).send_keys :enter
      expect(continue_button[:disabled]).to eq "true"

      fill_in "First name", with: new_individual_claimant[:first_name]
      expect(continue_button[:disabled]).to eq "true"
      fill_in "Last name", with: new_individual_claimant[:last_name]
      expect(continue_button[:disabled]).to eq "true"
      click_does_not_have_va_form
      expect(continue_button[:disabled]).to eq "false"

      # Reload page and change the relationship to other as individual to check the required fields
      visit "/intake/add_claimant"
      continue_button = find("button", text: "Continue to next step")
      fill_in("Relationship to the Veteran", with: other_claimant_type).send_keys :enter
      expect(continue_button[:disabled]).to eq "true"
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Individual", match: :prefer_exact).click
      end
      fill_in "First name", with: new_individual_claimant[:first_name]
      expect(continue_button[:disabled]).to eq "true"
      fill_in "Last name", with: new_individual_claimant[:last_name]
      expect(continue_button[:disabled]).to eq "true"
      click_does_not_have_va_form
      expect(continue_button[:disabled]).to eq "false"

      # Reload page and change the relationship to healthcare provider as individual to check the required fields
      visit "/intake/add_claimant"
      continue_button = find("button", text: "Continue to next step")
      fill_in("Relationship to the Veteran", with: healthcare_provider_claimant_type).send_keys :enter
      expect(continue_button[:disabled]).to eq "true"
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Individual", match: :prefer_exact).click
      end
      fill_in "First name", with: new_individual_claimant[:first_name]
      expect(continue_button[:disabled]).to eq "true"
      fill_in "Last name", with: new_individual_claimant[:last_name]
      expect(continue_button[:disabled]).to eq "true"
      click_does_not_have_va_form
      expect(continue_button[:disabled]).to eq "false"

      # Reload page and change the relationship to Attorney as individual to check the required fields
      visit "/intake/add_claimant"
      continue_button = find("button", text: "Continue to next step")
      fill_in("Relationship to the Veteran", with: attorney_claimant_type).send_keys :enter
      # Uh oh this doesn't work for this searchable dropdown
      # fill_in("Claimant's name", with: "Name not listed").send_keys :enter
      fill_in("Claimant's name", with: "Name not listed")
      find("div", class: "cf-select__option", text: "Name not listed").click
      expect(continue_button[:disabled]).to eq "true"
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Individual", match: :prefer_exact).click
      end

      # Verify the radio selection is gone if the type is attorney
      expect(page).to_not have_content("Do you have a VA Form 21-22 for this claimant?")

      fill_in "First name", with: new_individual_claimant[:first_name]
      expect(continue_button[:disabled]).to eq "true"
      fill_in "Last name", with: new_individual_claimant[:last_name]
      expect(continue_button[:disabled]).to eq "false"
    end
  end

  context "creating Supplemental Claims with unlisted claimants" do
    let(:intake_type) do
      start_supplemental_claim(veteran, is_comp: false, no_claimant: true)
    end

    it_behaves_like "HLR/SC intake unlisted claimant"
  end

  context "creating Higher Level Reviews with unlisted claimants" do
    let(:intake_type) do
      start_higher_level_review(veteran, is_comp: false, no_claimant: true)
    end

    it_behaves_like "HLR/SC intake unlisted claimant"
  end
end
