# frozen_string_literal: true

feature "Higher-Level Review and Supplemental Claims Unlisted Claimants", :all_dbs do
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
    FeatureToggle.enable!(:hlr_sc_unrecognized_claimants)
  end
  after do
    FeatureToggle.disable!(:filed_by_va_gov_hlr)
    FeatureToggle.disable!(:updated_intake_forms)
    FeatureToggle.disable!(:hlr_sc_unrecognized_claimants)
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

  let(:new_organization_claimant) do
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

  let(:new_individual_attorney) do
    {
      first_name: "Danny",
      last_name: "ThaAttorney",
      address1: "555 Rush Lane",
      city: "New York City",
      state: "NY",
      # Required for the regex matcher to work since the page modal displays the full state namee
      full_state: "New York",
      zip: "10001",
      country: "United States",
      email: "attorney@example.com"
    }
  end

  let(:new_organization_attorney) do
    {
      organization_name: "Attorney R Us",
      address1: "555 Rush Lane",
      city: "New York City",
      state: "NY",
      # Required for the regex matcher to work since the page modal displays the full state name
      full_state: "New York",
      zip: "10001",
      country: "United States",
      email: "attorney@example.com"
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

  def click_claimant_not_listed
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end

    within_fieldset(COPY::SELECT_CLAIMANT_LABEL) do
      find("label", text: "Claimant not listed", match: :prefer_exact).click
    end
  end

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
    fill_in "Organization name", with: new_organization_claimant[:organization_name]
    fill_in "Street address 1", with: new_organization_claimant[:address1]
    fill_in "City", with: new_organization_claimant[:city]
    fill_in("State", with: new_organization_claimant[:state]).send_keys :enter
    fill_in("Zip", with: new_organization_claimant[:zip]).send_keys :enter
    fill_in("Country", with: new_organization_claimant[:country]).send_keys :enter
    fill_in "Claimant email", with: new_organization_claimant[:email]
  end

  def add_new_organization_attorney
    fill_in "Organization name", with: new_organization_attorney[:organization_name]
    fill_in "Street address 1", with: new_organization_attorney[:address1]
    fill_in "City", with: new_organization_attorney[:city]
    fill_in("State", with: new_organization_attorney[:state]).send_keys :enter
    fill_in("Zip", with: new_organization_attorney[:zip]).send_keys :enter
    fill_in("Country", with: new_organization_attorney[:country]).send_keys :enter
    fill_in "Representative email", with: new_organization_attorney[:email]
  end

  def add_new_individual_attorney
    fill_in "First name", with: new_individual_attorney[:first_name]
    fill_in "Last name", with: new_individual_attorney[:last_name]
    fill_in "Street address 1", with: new_individual_attorney[:address1]
    fill_in "City", with: new_individual_attorney[:city]
    fill_in("State", with: new_individual_attorney[:state]).send_keys :enter
    fill_in("Zip", with: new_individual_attorney[:zip]).send_keys :enter
    fill_in("Country", with: new_individual_attorney[:country]).send_keys :enter
    fill_in "Representative email", with: new_individual_attorney[:email]
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

  def unlisted_attorney_with_party_type(is_organization = true)
    expect(page).to have_content("Is the representative an organization or individual?")
    party_type = is_organization ? "Organization" : "Individual"
    within_fieldset("Is the representative an organization or individual?") do
      find("label", text: party_type, match: :prefer_exact).click
    end
  end

  def select_organization_party_type
    unlisted_claimant_with_party_type true
  end

  def select_individual_party_type
    unlisted_claimant_with_party_type false
  end

  def select_attorney_organization_party_type
    unlisted_attorney_with_party_type true
  end

  def select_attorney_individual_party_type
    unlisted_attorney_with_party_type false
  end

  def click_has_va_form(option_text = "Yes")
    within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
      find("label", text: option_text, match: :prefer_exact).click
    end
  end

  def click_does_not_have_va_form(option_text = "No")
    click_has_va_form(option_text)
  end

  def verify_individual_add_claimant_modal_information(has_poa = false)
    claimant_name = "#{new_individual_claimant[:first_name]} #{new_individual_claimant[:last_name]}"

    within("#add_claimant_modal") do
      expect(page).to have_content("Review and confirm claimant information")
      expect(page).to have_content(claimant_name)
      if !has_poa
        expect(page).to have_content("Intake does not have a Form 21-22")
      end
    end
  end

  def verify_organization_add_claimant_modal_information(has_poa = false)
    within("#add_claimant_modal") do
      expect(page).to have_content("Review and confirm claimant information")
      expect(page).to have_content(new_organization_claimant[:organization_name])
      if !has_poa
        expect(page).to have_content("Intake does not have a Form 21-22")
      end
    end
  end

  def verify_add_claimant_modal_information_with_new_attorney(claimant_is_individual = true)
    if claimant_is_individual
      verify_individual_add_claimant_modal_information(has_poa: true)
    else
      verify_organization_add_claimant_modal_information(has_poa: true)
    end

    # Verify Additional PoA information
    within("#add_claimant_modal") do
      expect(page).to have_content("Claimant's POA")
      expect(page).to have_content(new_attorney_name)
      expect(page.text).to match(%r{#{new_attorney_street_address}}i)
      expect(page.text).to match(%r{#{new_attorney_city_address_line}}i)
    end
  end

  def verify_add_claimant_modal_information_with_existing_attorney(claimant_is_individual = true)
    if claimant_is_individual
      verify_individual_add_claimant_modal_information(has_poa: true)
    else
      verify_organization_add_claimant_modal_information(has_poa: true)
    end

    # Verify Additional PoA information
    within("#add_claimant_modal") do
      expect(page).to have_content("Claimant's POA")
      expect(page).to have_content(attorney.name)
      expect(page.text).to match(%r{#{attorney.address[:address_line_1]}}i)
      expect(page.text).to match(%r{#{attorney_city_address_line}}i)
    end
  end

  def verify_individual_claimant_on_add_issues
    expect(page).to have_content("Add / Remove Issues")
    # Fix the attorney string for the test
    claimant_type_string = (claimant_type == "Attorney (previously or currently)") ? "Attorney" : claimant_type
    claimant_name = "#{new_individual_claimant[:first_name]} #{new_individual_claimant[:last_name]}"
    claimant_string = "#{claimant_name}, #{claimant_type_string}"
    expect(page).to have_content(claimant_string)
  end

  def verify_organization_claimant_on_add_issues
    expect(page).to have_content("Add / Remove Issues")
    # Fix the attorney string for the test
    claimant_type_string = (claimant_type == "Attorney (previously or currently)") ? "Attorney" : claimant_type
    claimant_string = "#{new_organization_claimant[:organization_name]}, #{claimant_type_string}"
    expect(page).to have_content(claimant_string)
  end

  def advance_to_add_unlisted_claimant_page
    start_intake
    visit "/intake/"
    click_claimant_not_listed
    click_intake_continue

    # Select claimant type specified by each test type
    fill_in("Relationship to the Veteran", with: claimant_type).send_keys :enter
  end

  def add_existing_attorney(attorney)
    fill_in "Claimant's name", with: attorney.name
    find("div", class: "cf-select__option", text: attorney.name).click
  end

  def add_existing_attorney_on_poa_page(attorney)
    fill_in "Representative's name", with: attorney.name
    find("div", class: "cf-select__option", text: attorney.name).click
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

    context("attorney unlisted claimant") do
      let(:claimant_type) do
        attorney_claimant_type
      end

      context("attorney claimant Name not listed") do
        scenario "unlisted claimant with relationship attorney with Name not listed with party type individual" do
          advance_to_add_unlisted_claimant_page

          # Unidentified attorney
          fill_in("Claimant's name", with: "Name not listed")
          find("div", class: "cf-select__option", text: "Name not listed").click
          select_individual_party_type
          add_new_individual_claimant
          click_button "Continue to next step"
          expect(page).to have_content("Review and confirm claimant information")
          expect(page).to have_content("Intake does not have a Form 21-22")
          click_button "Confirm"
          verify_individual_claimant_on_add_issues
        end

        scenario "unlisted claimant with relationship attorney with Name not listed with party type organization" do
          advance_to_add_unlisted_claimant_page
          # Unidentified attorney
          fill_in("Claimant's name", with: "Name not listed")
          find("div", class: "cf-select__option", text: "Name not listed").click
          select_organization_party_type
          add_new_organization_claimant
          click_button "Continue to next step"
          expect(page).to have_content("Review and confirm claimant information")
          expect(page).to have_content("Intake does not have a Form 21-22")
          click_button "Confirm"
          verify_organization_claimant_on_add_issues
        end
      end

      context("existing attorney") do
        let(:attorneys) do
          Array.new(15) { create(:bgs_attorney) }
        end

        let(:attorney) do
          attorneys.last
        end

        scenario "unlisted claimant with relationship attorney that already exists" do
          advance_to_add_unlisted_claimant_page
          add_existing_attorney(attorney)
          click_button "Continue to next step"
          expect(page).to have_content("Review and confirm claimant information")
          match_string = attorney.address[:address_line_1]
          expect(page.text).to match(%r{#{match_string}}i)
          expect(page).to have_content("Intake does not have a Form 21-22")
          click_button "Confirm"
          expect(page).to have_content("Add / Remove Issues")
          expect(page).to have_content("#{attorney.name}, Attorney")
        end
      end
    end

    context("other unlisted claimant") do
      let(:claimant_type) do
        other_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship other with type individual" do
        advance_to_add_unlisted_claimant_page
        select_individual_party_type
        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"
        verify_individual_add_claimant_modal_information

        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship other with type organization" do
        advance_to_add_unlisted_claimant_page

        select_organization_party_type
        add_new_organization_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        verify_organization_add_claimant_modal_information

        click_button "Confirm"

        verify_organization_claimant_on_add_issues
      end
    end

    context("healthcare provider unlisted claimant") do
      let(:claimant_type) do
        healthcare_provider_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant " \
        "with relationship Healthcare Provider with type individual" do
        advance_to_add_unlisted_claimant_page
        select_individual_party_type
        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"
        verify_individual_add_claimant_modal_information

        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship " \
        "healthcare provider with type organization" do
        advance_to_add_unlisted_claimant_page
        select_organization_party_type
        add_new_organization_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"
        verify_organization_add_claimant_modal_information

        click_button "Confirm"

        verify_organization_claimant_on_add_issues
      end
    end

    context("child provider unlisted claimant") do
      let(:claimant_type) do
        child_provider_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship Child" do
        advance_to_add_unlisted_claimant_page

        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review claimant modal
        verify_individual_add_claimant_modal_information
        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end
    end

    context("spouse provider unlisted claimant") do
      let(:claimant_type) do
        spouse_provider_claimant_type
      end

      scenario "creating a HLR/SC intake with an unlisted claimant with relationship Spouse" do
        advance_to_add_unlisted_claimant_page

        add_new_individual_claimant
        click_does_not_have_va_form
        click_button "Continue to next step"

        # Review claimant modal
        expect(page).to have_content("Review and confirm claimant information")
        click_button "Confirm"

        verify_individual_claimant_on_add_issues
      end
    end

    context("other claimant with a Form 21-22 ") do
      let(:claimant_type) do
        other_claimant_type
      end

      context("existing attorney") do
        let(:attorneys) do
          Array.new(15) { create(:bgs_attorney) }
        end

        let(:attorney) do
          attorneys.last
        end

        let(:address) do
          attorney.address
        end

        let(:attorney_city_address_line) do
          "#{address[:city]}, #{address[:state]} #{address[:zip]} #{address[:country]}"
        end

        scenario "unlisted individual other claimant with form 21-22 add existing attorney" do
          advance_to_add_unlisted_claimant_page
          select_individual_party_type
          add_new_individual_claimant
          click_has_va_form
          click_button "Continue to next step"
          expect(page).to have_content("Add Claimant's POA")
          expect(current_path).to eq("/intake/add_power_of_attorney")
          add_existing_attorney_on_poa_page(attorney)
          # Check if the address was added to page successfully
          match_string = attorney.address[:address_line_1]
          expect(page.text).to match(%r{#{match_string}}i)

          # Continue on and verify the modal information for add claimant and add poa pages
          click_button "Continue to next step"
          verify_add_claimant_modal_information_with_existing_attorney(claimant_is_individual: true)
          click_button "Confirm"
          verify_individual_claimant_on_add_issues
        end
      end

      context("name not listed individual attorney") do
        let(:new_attorney) do
          new_individual_attorney
        end
        let(:new_attorney_name) do
          "#{new_attorney[:first_name]} #{new_attorney[:last_name]}"
        end
        let(:new_attorney_street_address) do
          new_attorney[:street_address_1]
        end
        let(:new_attorney_city_address_line) do
          "#{new_attorney[:city]}, #{new_attorney[:full_state]} #{new_attorney[:zip]} #{new_attorney[:country]}"
        end

        scenario "unlisted individual other claimant with form 21-22 add name not listed individual attorney" do
          advance_to_add_unlisted_claimant_page
          select_individual_party_type
          add_new_individual_claimant
          click_has_va_form
          click_button "Continue to next step"
          expect(page).to have_content("Add Claimant's POA")
          expect(current_path).to eq("/intake/add_power_of_attorney")

          # Enter name not listed and information for the new attorney
          fill_in("Representative's name", with: "Name not listed")
          find("div", class: "cf-select__option", text: "Name not listed").click
          select_attorney_individual_party_type
          add_new_individual_attorney
          click_button "Continue to next step"
          verify_add_claimant_modal_information_with_new_attorney(claimant_is_individual: true)
          click_button "Confirm"
          verify_individual_claimant_on_add_issues
        end
      end

      context("name not listed organization attorney") do
        let(:new_attorney) do
          new_organization_attorney
        end
        let(:new_attorney_name) do
          new_attorney[:organization_name]
        end
        let(:new_attorney_street_address) do
          new_attorney[:street_address_1]
        end
        let(:new_attorney_city_address_line) do
          "#{new_attorney[:city]}, #{new_attorney[:full_state]} #{new_attorney[:zip]} #{new_attorney[:country]}"
        end

        scenario "unlisted individual other claimant with form 21-22 add name not listed individual attorney" do
          advance_to_add_unlisted_claimant_page
          select_individual_party_type
          add_new_individual_claimant
          click_has_va_form
          click_button "Continue to next step"
          expect(page).to have_content("Add Claimant's POA")
          expect(current_path).to eq("/intake/add_power_of_attorney")

          # Enter name not listed and information for the new attorney
          fill_in("Representative's name", with: "Name not listed")
          find("div", class: "cf-select__option", text: "Name not listed").click
          select_attorney_organization_party_type
          add_new_organization_attorney
          click_button "Continue to next step"
          verify_add_claimant_modal_information_with_new_attorney(claimant_is_individual: true)
          click_button "Confirm"
          verify_individual_claimant_on_add_issues
        end
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
