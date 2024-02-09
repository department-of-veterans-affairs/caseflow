# frozen_string_literal: true

## This feature spec covers non-veteran claimants for Appeals when they are not listed in the veteran's relationships

feature "Non-veteran claimants", :postgres do
  include IntakeHelpers

  before do
    setup_intake_flags
  end

  let(:veteran_file_number) { "123412345" }
  let!(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end
  let(:benefit_type) { "compensation" }

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

  let(:decision_date) { 3.months.ago.mdY }

  context "when intaking appeals with non_veteran_claimants" do
    before { FeatureToggle.enable!(:hlr_sc_unrecognized_claimants) }
    after { FeatureToggle.disable!(:hlr_sc_unrecognized_claimants) }

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

      expect(page).to have_button("Continue to next step", disabled: false)

      # Verify that this can be removed
      find(".cf-select__clear-indicator").click
      expect(page).to_not have_selector("option", text: attorney.name)
      expect(page).to_not have_content("Claimant's address")
      expect(page).to have_button("Continue to next step", disabled: true)
      expect(page).to have_content("Type to search...")

      safe_click ".dropdown-listedAttorney"
      fill_in("Claimant's name", with: "Name not listed")
      expect(page).to have_content("Name not listed")
      find("div", class: "cf-select__menu", text: "Name not listed")
      select_claimant(0)

      expect(page).to have_content("Is the claimant an organization or individual?")

      # Check validation for unlisted attorney
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Organization", match: :prefer_exact).click
      end

      expect(page).to have_no_content(COPY::EMPLOYER_IDENTIFICATION_NUMBER)
      fill_in "Organization name", with: "Attorney's Law Firm"
      fill_in "Street address 1", with: "1234 Justice St."
      fill_in "City", with: "Anytown"
      fill_in("State", with: "CA").send_keys :enter
      fill_in("Zip", with: "12345").send_keys :enter
      fill_in("Country", with: "United States").send_keys :enter

      expect(page).to have_button("Continue to next step", disabled: false)

      click_button "Continue to next step"
      submit_confirmation_modal

      expect(page).to have_current_path("/intake/add_issues")

      click_intake_add_issue
      add_intake_nonrating_issue(date: decision_date)

      expect(page).to have_content("Active Duty Adjustments")

      click_intake_finish

      expect(page).to have_current_path("/intake/completed")

      appeal = Appeal.find_by(docket_type: "evidence_submission")

      expect(appeal.claimant.name).to eq "Attorney's Law Firm"

      # Check that data clears for immediate next intake
      click_button "Begin next intake"
      expect(page).to have_current_path("/intake/")
      select_form(Constants.INTAKE_FORM_NAMES.appeal)
      safe_click ".cf-submit.usa-button"
      expect(page).to have_content(search_page_title)
      fill_in search_bar_title, with: veteran_file_number
      click_on "Search"
      expect(page).to have_current_path("/intake/review_request")
      populate_review_data

      expect(page).to have_current_path("/intake/add_claimant")
      expect(page).to have_no_content(appeal.claimant.name)
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
        find("label", text: "Individual", match: :prefer_exact).click
      end
      expect(page).to have_button("Continue to next step", disabled: true)

      # fill in form information
      add_new_claimant

      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end

      expect(page).to have_button("Continue to next step", disabled: false)
      click_button "Continue to next step"
      expect(page).to have_current_path("/intake/add_power_of_attorney")
      expect(page).to have_content("Add Claimant's POA")
      expect(page).to have_button("Continue to next step", disabled: true)

      # add poa
      add_existing_poa(attorney)
      expect(page).to have_content("Representative's address")
      find(".cf-select__clear-indicator").click

      expect(page).to_not have_selector("option", text: attorney.name)
      expect(page).to_not have_content("Representative's address")
      expect(page).to have_content("Type to search...")
      expect(page).to have_button("Continue to next step", disabled: true)
      # Fill in Name not listed
      safe_click ".dropdown-listedAttorney"
      fill_in("Representative's name", with: "Name not listed")
      expect(page).to have_content("Name not listed")
      find("div", class: "cf-select__menu", text: "Name not listed")
      select_claimant(0)

      expect(page).to have_content("Is the representative an organization or individual?")

      # Check validation for unlisted attorney
      within_fieldset("Is the representative an organization or individual?") do
        find("label", text: "Organization", match: :prefer_exact).click
      end

      add_new_poa

      expect(page).to have_button("Continue to next step", disabled: false)

      click_button "Continue to next step"

      submit_confirmation_modal

      expect(page).to have_current_path("/intake/add_issues")
      expect(page).to have_content("Claimant's POA")
      expect(page).to have_content(new_individual_claimant[:first_name])

      # Add request issues
      click_intake_add_issue
      add_intake_nonrating_issue(date: decision_date)
      expect(page).to have_content("Active Duty Adjustments")
      click_intake_finish
      expect(page).to have_current_path("/intake/completed")

      # verify that current intake with claimant_type other was created
      expect(Intake.last.detail.claimant_type).to eq("other")
      claimant = Claimant.find_by(type: "OtherClaimant")
      expect(claimant.power_of_attorney.name).to eq("Attorney's Law Firm")
      appeal = Appeal.find_by(docket_type: "evidence_submission")

      # Check that claimant data clears for immediate next intake
      click_button "Begin next intake"
      expect(page).to have_current_path("/intake/")
      select_form(Constants.INTAKE_FORM_NAMES.appeal)
      safe_click ".cf-submit.usa-button"
      expect(page).to have_content(search_page_title)
      fill_in search_bar_title, with: veteran_file_number
      click_on "Search"
      expect(page).to have_current_path("/intake/review_request")
      populate_review_data

      expect(page).to have_current_path("/intake/add_claimant")
      expect(page).to have_content("Add Claimant")
      expect(page).to have_no_content(appeal.claimant.name)

      # Check that POA data cleared from previous intake
      fill_in("Relationship to the Veteran", with: "Other").send_keys :enter
      expect(page).to have_content("Is the claimant an organization or individual?")
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Individual", match: :prefer_exact).click
      end
      add_new_claimant
      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end
      click_button "Continue to next step"

      expect(page).to have_current_path("/intake/add_power_of_attorney")
      expect(page).to have_content("Add Claimant's POA")
      expect(page).to have_no_content(claimant.power_of_attorney.name)

      # verify poa shows on edit page
      visit "/appeals/#{appeal.uuid}/edit"
      expect(page).to have_content(claimant.power_of_attorney.name)

      # Case details page
      reload_case_detail_page(appeal.uuid)

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      expect(page).to have_content(new_individual_claimant[:first_name])
      expect(claimant.relationship).to eq("Other")
    end

    it "allows selecting claimant not listed and validates spouse is saved on review page" do
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

      fill_in("Relationship to the Veteran", with: "Spouse").send_keys :enter

      # fill in form information
      fill_in "First name", with: "Darlyn"
      fill_in "Last name", with: "Duck"
      fill_in "Street address 1", with: "1234 Justice St."
      fill_in "City", with: "Anytown"
      fill_in("State", with: "CA").send_keys :enter
      fill_in("Zip", with: "12345").send_keys :enter
      fill_in("Country", with: "United States").send_keys :enter
      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "No", match: :prefer_exact).click
      end

      expect(page).to have_button("Continue to next step", disabled: false)
      click_button "Continue to next step"
      expect(page).to have_content(COPY::ADD_CLAIMANT_CONFIRM_MODAL_NO_POA)
      submit_confirmation_modal

      expect(page).to have_content("Darlyn Duck")
      claimant = Claimant.find_by(type: "OtherClaimant")
      expect(claimant.name).to eq("Darlyn Duck")
      expect(claimant.relationship).to eq("Spouse")

      # Add request issues
      click_intake_add_issue
      add_intake_nonrating_issue(date: decision_date)
      expect(page).to have_content("Active Duty Adjustments")
      click_intake_finish
      expect(page).to have_current_path("/intake/completed")

      appeal = Appeal.find_by(docket_type: "evidence_submission")
      # Case details page
      visit "queue/appeals/#{appeal.uuid}"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      expect(claimant.name).to eq("Darlyn Duck")
      expect(claimant.relationship).to eq("Spouse")
    end

    it "returns to review page if data is reloaded before saving" do
      BvaIntake.singleton.add_user(current_user)
      visit "/intake"
      select_form(Constants.INTAKE_FORM_NAMES.appeal)
      safe_click ".cf-submit.usa-button"
      expect(page).to have_content(search_page_title)
      fill_in search_bar_title, with: veteran_file_number
      click_on "Search"
      expect(page).to have_current_path("/intake/review_request")
      populate_review_data

      expect(page).to have_current_path("/intake/add_claimant")
      expect(page).to have_content("Add Claimant")

      fill_in("Relationship to the Veteran", with: "Other").send_keys :enter
      expect(page).to have_content("Is the claimant an organization or individual?")
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Individual", match: :prefer_exact).click
      end
      add_new_claimant

      visit "/intake/add_claimant"

      # Re-routes back to Review page
      expect(page).to have_current_path("/intake/review_request")
      populate_review_data
      expect(page).to have_current_path("/intake/add_claimant")
      fill_in("Relationship to the Veteran", with: "Spouse").send_keys :enter
      add_new_claimant

      within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
        find("label", text: "Yes", match: :prefer_exact).click
      end
      click_button "Continue to next step"
      expect(page).to have_current_path("/intake/add_power_of_attorney")
      expect(page).to have_content("Add Claimant's POA")

      # add poa
      safe_click ".dropdown-listedAttorney"
      fill_in("Representative's name", with: "Name not listed")
      expect(page).to have_content("Name not listed")
      find("div", class: "cf-select__menu", text: "Name not listed")
      select_claimant(0)
      within_fieldset("Is the representative an organization or individual?") do
        find("label", text: "Organization", match: :prefer_exact).click
      end
      add_new_poa

      visit "/intake/add_power_of_attorney"

      # Re-routes back to Review page
      expect(page).to have_current_path("/intake/review_request")
    end

    context "with edit_unrecognized_appellant" do
      before { FeatureToggle.enable!(:edit_unrecognized_appellant) }
      after { FeatureToggle.disable!(:edit_unrecognized_appellant) }

      it "shows edit information button" do
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

        fill_in("Relationship to the Veteran", with: "Spouse").send_keys :enter

        # fill in form information
        fill_in "First name", with: "Darlyn"
        fill_in "Last name", with: "Duck"
        fill_in "Street address 1", with: "1234 Justice St."
        fill_in "City", with: "Anytown"
        fill_in("State", with: "CA").send_keys :enter
        fill_in("Zip", with: "12345").send_keys :enter
        fill_in("Country", with: "United States").send_keys :enter
        within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
          find("label", text: "No", match: :prefer_exact).click
        end

        expect(page).to have_button("Continue to next step", disabled: false)
        click_button "Continue to next step"
        expect(page).to have_content(COPY::ADD_CLAIMANT_CONFIRM_MODAL_NO_POA)
        submit_confirmation_modal

        expect(page).to have_content("Darlyn Duck")
        claimant = Claimant.find_by(type: "OtherClaimant")
        expect(claimant.name).to eq("Darlyn Duck")
        expect(claimant.relationship).to eq("Spouse")

        # Add request issues
        click_intake_add_issue
        add_intake_nonrating_issue(date: decision_date)
        expect(page).to have_content("Active Duty Adjustments")
        click_intake_finish
        expect(page).to have_current_path("/intake/completed")

        appeal = Appeal.find_by(docket_type: "evidence_submission")
        # Case details page
        visit "queue/appeals/#{appeal.uuid}"
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
        expect(claimant.name).to eq("Darlyn Duck")
        expect(claimant.relationship).to eq("Spouse")

        expect(page).to have_content("Edit Information")
        click_on "Edit Information"

        expect(page).to have_content("Edit Appellant Information")
        # Check that form is prepopulated with existing appellant information
        expect(find("#firstName").value).to eq "Darlyn"
        expect(find("#lastName").value).to eq "Duck"
      end
    end

    context "when intaking a Higher Level Review with a non-veteran claimant" do
      it "HLR with Non-Veteran Claimant and VBMS Benefit Type" do
        start_higher_level_review(
          veteran,
          benefit_type: "compensation"
        )
        visit "/intake"

        expect(page).to have_current_path("/intake/review_request")

        within_fieldset("Is the claimant someone other than the Veteran?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        expect(page).to have_no_content("Claimant not listed")
        expect(page).to have_content("What is the payee code for this claimant?")
      end

      it "HLR with Non-Veteran Claimant and Non-VBMS Benefit Type" do
        start_higher_level_review(
          veteran,
          benefit_type: "insurance"
        )
        visit "/intake"

        expect(page).to have_current_path("/intake/review_request")

        within_fieldset("Is the claimant someone other than the Veteran?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        expect(page).to have_content("Claimant not listed")
        expect(page).to have_no_content("What is the payee code for this claimant?")
      end
    end

    context "when intaking a Supplemental Claim with a non-veteran claimant" do
      it "SC with Non-Veteran Claimant and VBMS Benefit Type" do
        start_supplemental_claim(
          veteran,
          benefit_type: "compensation"
        )
        visit "/intake"

        expect(page).to have_current_path("/intake/review_request")

        within_fieldset("Is the claimant someone other than the Veteran?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        expect(page).to have_no_content("Claimant not listed")
        expect(page).to have_content("What is the payee code for this claimant?")
      end

      it "SC with Non-Veteran Claimant and Non-VBMS Benefit Type" do
        start_supplemental_claim(
          veteran,
          benefit_type: "insurance"
        )
        visit "/intake"

        expect(page).to have_current_path("/intake/review_request")

        within_fieldset("Is the claimant someone other than the Veteran?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        expect(page).to have_content("Claimant not listed")
        expect(page).to have_no_content("What is the payee code for this claimant?")
      end
    end

    context "when the veteran has no dependent relations" do
      it "allows selecting claimant not listed" do
        allow_any_instance_of(Veteran).to receive(:relationships).and_return([])
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

        expect(page).to have_button("Continue to next step", disabled: false)
      end
    end

    context "when the user cancels the intake on the Add POA page" do
      it "redirects back to the Intake start page" do
        start_appeal(veteran, receipt_date: "09/01/2022")

        # Review page
        visit "/intake"
        expect(page).to have_current_path("/intake/review_request")
        within_fieldset("Is the claimant someone other than the Veteran?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        find("label", text: "Claimant not listed", match: :prefer_exact).click
        click_intake_continue

        # Add Claimant Page
        fill_in("Relationship to the Veteran", with: "Spouse").send_keys :enter

        fill_in "First name", with: Faker::Name.first_name
        fill_in "Last name", with: Faker::Name.last_name
        fill_in "Street address 1", with: Faker::Address.street_address
        fill_in "City", with: Faker::Address.city
        fill_in("State", with: Faker::Address.state_abbr).send_keys :enter
        fill_in("Zip", with: "12345").send_keys :enter
        fill_in("Country", with: "United States").send_keys :enter
        within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        click_intake_continue

        # Add POA Page
        expect(page).to have_content("Add Claimant's POA")
        expect(page).to have_current_path("/intake/add_power_of_attorney")

        # Cancellation Modal
        safe_click "#cancel-intake"
        within_fieldset("Please select the reason you are canceling this intake.") do
          find("label", text: "System error").click
        end
        safe_click ".confirm-cancel"

        # Post-redirect to homepage
        expect(page).to have_content("Welcome to Caseflow Intake!")
        expect(page).to have_current_path("/intake/")
      end
    end

    context "when user select name not listed claimant for VHA benefit type" do
      before do
        start_higher_level_review(
          veteran,
          benefit_type: "vha"
        )
        visit "/intake"
      end

      context "should display an alert banner" do
        it "for claimant name not listed and display Un recognized POA in Claimant model and case detail page" do
          expect(page).to have_current_path("/intake/review_request")
          first_name = Faker::Name.first_name
          last_name = Faker::Name.last_name

          within_fieldset("Is the claimant someone other than the Veteran?") do
            find("label", text: "Yes", match: :prefer_exact).click
          end
          find("label", text: "Claimant not listed", match: :prefer_exact).click
          click_intake_continue

          step "Add Claimant Page" do
            # Add Claimant Page
            fill_in("Relationship to the Veteran", with: "child").send_keys :enter
            fill_in "First name", with: first_name
            fill_in "Last name", with: last_name
            fill_in "Street address 1", with: Faker::Address.street_address
            fill_in "City", with: Faker::Address.city
            fill_in("State", with: Faker::Address.state_abbr).send_keys :enter
            fill_in("Zip", with: "12345").send_keys :enter
            fill_in("Country", with: "United States").send_keys :enter
            within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
              find("label", text: "Yes", match: :prefer_exact).click
            end
            click_intake_continue
          end

          step "Add POA Page" do
            # Add POA Page
            expect(page).to have_content("Add Claimant's POA")
            expect(page).to have_current_path("/intake/add_power_of_attorney")
            fill_in("Representative's name", with: "Name not listed")
            find("div", class: "cf-select__option", text: "Name not listed").click
            expect(page).to have_content(COPY::VHA_POA_NAME_NOT_LISTED)
            continue_button = find("button", text: "Continue to next step")
            expect(continue_button[:disabled]).to eq "false"
            continue_button.click
          end

          step "Add claimant modal" do
            # Add claimant modal
            within("#add_claimant_modal") do
              expect(page).to have_content("Review and confirm claimant information")
              expect(page).to have_content("#{first_name} #{last_name}")
              expect(page).to have_content(COPY::VHA_NO_RECOGNIZED_POA)
              click_button "Confirm"
            end
          end

          expect(page).to have_current_path("/intake/add_issues")

          # Add issue that is not a VBMS issue
          step "Add issue that is not a VBMS issue" do
            click_intake_add_issue
          end

          # click_intake_no_matching_issues
          step "click intake no matching issues" do
            add_intake_vha_issue(date: 2.days.ago, category: "Beneficiary Travel")
          end

          click_intake_finish

          step "go to case detail page" do
            # go to case detail page
            find("a", text: "#{first_name} #{last_name}", match: :prefer_exact).click
            expect(page).to have_content("Veterans Health Administration")
            expect(page).to have_content(COPY::CASE_DETAILS_NO_RECOGNIZED_POA_VHA)
          end
        end
      end

      it "should display No Known POA when child no VA form 21-22 is selected as a claimant" do
        expect(page).to have_current_path("/intake/review_request")
        within_fieldset("Is the claimant someone other than the Veteran?") do
          find("label", text: "Yes", match: :prefer_exact).click
        end
        find("label", text: "Claimant not listed", match: :prefer_exact).click
        click_intake_continue

        # Add Claimant Page
        fill_in("Relationship to the Veteran", with: "child").send_keys :enter
        first_name = Faker::Name.first_name
        last_name = Faker::Name.last_name
        fill_in "First name", with: first_name
        fill_in "Last name", with: last_name
        within_fieldset("Do you have a VA Form 21-22 for this claimant?") do
          find("label", text: "No", match: :prefer_exact).click
        end
        click_intake_continue

        within("#add_claimant_modal") do
          expect(page).to have_content("Review and confirm claimant information")
          expect(page).to have_content("#{first_name} #{last_name}")
          expect(page).to have_content(COPY::VHA_NO_POA)
          click_button "Confirm"
        end
      end

      it "should display No know POA when attorney if attorney is selected after claimant not listed is selected" do
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

        expect(page).to have_button("Continue to next step", disabled: false)
        click_button "Continue to next step"

        within("#add_claimant_modal") do
          expect(page).to have_content("Review and confirm claimant information")
          expect(page).to have_content(COPY::VHA_NO_POA)

          click_button "Confirm"
        end
        expect(page).to have_current_path("/intake/add_issues")
        expect(page).to have_content("Add / Remove Issues")
        expect(page).to have_content(COPY::VHA_NO_POA)
        expect(page).to have_content "Add Issue"
      end

      it "should display No known POA when new attorney is added after claimant not listed is selected" do
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

        # add poa
        fill_in("Relationship to the Veteran", with: "Attorney (previously or currently)").send_keys :enter
        fill_in("Claimant's name", with: "Name not listed")

        expect(page).to have_content("Name not listed")
        find("div", class: "cf-select__menu", text: "Name not listed")
        select_claimant(0)
        within_fieldset("Is the claimant an organization or individual?") do
          find("label", text: "Organization", match: :prefer_exact).click
        end
        add_new_poa

        expect(page).to have_button("Continue to next step", disabled: false)
        click_button "Continue to next step"

        within("#add_claimant_modal") do
          expect(page).to have_content("Review and confirm claimant information")
          expect(page).to have_content(COPY::VHA_NO_POA)

          click_button "Confirm"
        end
        expect(page).to have_current_path("/intake/add_issues")
        expect(page).to have_content("Add / Remove Issues")
        expect(page).to have_content(COPY::VHA_NO_POA)
        expect(page).to have_content "Add Issue"
      end
    end
  end

  def add_existing_attorney(attorney)
    fill_in "Claimant's name", with: attorney.name
    select_claimant(0)
  end

  def add_existing_poa(attorney)
    fill_in "Representative's name", with: attorney.name
    select_claimant(0)
  end

  def add_new_claimant
    fill_in "First name", with: new_individual_claimant[:first_name]
    fill_in "Last name", with: new_individual_claimant[:last_name]
    fill_in "Street address 1", with: new_individual_claimant[:address1]
    fill_in "City", with: new_individual_claimant[:city]
    fill_in("State", with: new_individual_claimant[:state]).send_keys :enter
    fill_in("Zip", with: new_individual_claimant[:zip]).send_keys :enter
    fill_in("Country", with: new_individual_claimant[:country]).send_keys :enter
    fill_in "Claimant email", with: new_individual_claimant[:email]
  end

  def add_new_poa
    fill_in "Organization name", with: "Attorney's Law Firm"
    fill_in "Street address 1", with: "1234 Justice St."
    fill_in "City", with: "Anytown"
    fill_in("State", with: "CA").send_keys :enter
    fill_in("Zip", with: "12345").send_keys :enter
    fill_in("Country", with: "United States").send_keys :enter
  end

  def select_claimant(index = 0)
    click_dropdown({ index: index }, find(".dropdown-listedAttorney"))
  end

  def submit_confirmation_modal
    # Ensure it is showing
    expect(page).to have_content(COPY::ADD_CLAIMANT_CONFIRM_MODAL_TITLE)

    click_button "Confirm"

    expect(page).to_not have_content(COPY::ADD_CLAIMANT_CONFIRM_MODAL_TITLE)
  end

  def populate_review_data
    fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY
    within_fieldset("Was this form submitted through VA.gov?") do
      find("label", text: "No", match: :prefer_exact).click
    end
    click_intake_continue
    within_fieldset("Which review option did the Veteran request?") do
      find("label", text: "Evidence Submission", match: :prefer_exact).click
    end
    within_fieldset("Is the claimant someone other than the Veteran?") do
      find("label", text: "Yes", match: :prefer_exact).click
    end
    within_fieldset(COPY::SELECT_CLAIMANT_LABEL) do
      find("label", text: "Claimant not listed", match: :prefer_exact).click
    end
    select_agree_to_withdraw_legacy_issues(false)
    click_intake_continue
  end
end
