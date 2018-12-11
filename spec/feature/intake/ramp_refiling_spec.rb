require "rails_helper"

RSpec.feature "RAMP Refiling Intake" do
  before do
    FeatureToggle.enable!(:intake)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2017, 12, 8))

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
  end

  let(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let(:issues) do
    [
      Generators::Issue.build
    ]
  end

  let(:inaccessible) { false }

  let!(:appeal) do
    Generators::LegacyAppeal.build(
      vbms_id: "12341234C",
      issues: issues,
      vacols_record: :ready_to_certify,
      veteran: veteran,
      inaccessible: inaccessible,
      nod_date: 1.year.ago
    )
  end

  let(:ep_already_exists_error) do
    VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
      "A duplicate claim for this EP code already exists in CorpDB. Please " \
      "use a different EP code modifier. GUID: 13fcd</faultstring>")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:search_bar_title) { "Enter the Veteran's ID" }
  let(:search_page_title) { "Search for Veteran ID" }

  context "RAMP Refiling" do
    scenario "Attempt to start RAMP refiling for a veteran without a complete RAMP election" do
      # Create an incomplete RAMP election
      create(:ramp_election, veteran_file_number: "12341234", notice_date: 3.days.ago)

      # Validate that you can't go directly to search
      visit "/intake"

      # Validate that you can't move forward without selecting a form
      scroll_element_in_to_view(".cf-submit.usa-button")
      expect(find(".cf-submit.usa-button")["disabled"]).to eq("true")

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Selection (VA Form 21-4138)").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in search_bar_title, with: "12341234"
      click_on "Search"

      expect(page).to have_content("No RAMP Opt-In Election")
      expect(RampRefilingIntake.last).to have_attributes(error_code: "no_complete_ramp_election")
    end

    scenario "Attempt to start RAMP refiling for a veteran with an active RAMP Election EP" do
      # Create an RAMP election with a pending EP
      r = create(:ramp_election,
                 veteran_file_number: veteran.file_number,
                 notice_date: 3.days.ago,
                 established_at: 2.days.ago)

      claim_id = Generators::EndProduct.build(
        veteran_file_number: veteran.file_number,
        bgs_attrs: { status_type_code: "PEND" }
      ).claim_id

      EndProductEstablishment.create!(
        veteran_file_number: veteran.file_number,
        source: r,
        established_at: 2.days.ago,
        last_synced_at: 2.days.ago,
        synced_status: "PEND",
        reference_id: claim_id
      )

      # Validate that you can't go directly to search
      visit "/intake"

      # Validate that you can't move forward without selecting a form
      scroll_element_in_to_view(".cf-submit.usa-button")
      expect(find(".cf-submit.usa-button")["disabled"]).to eq("true")

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Selection (VA Form 21-4138)").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in search_bar_title, with: "12341234"
      click_on "Search"

      expect(page).to have_content("This Veteran has a pending RAMP EP in VBMS")
      expect(RampRefilingIntake.last).to have_attributes(error_code: "ramp_election_is_active")
    end

    scenario "Start a RAMP refiling with an invalid option" do
      # Create an complete Higher-Level Review RAMP election
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             option_selected: "higher_level_review_with_hearing",
                             receipt_date: 4.days.ago,
                             established_at: 2.days.ago)
      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      EndProductEstablishment.create(
        source: ramp_election,
        veteran_file_number: "12341234",
        reference_id: ep.claim_id,
        synced_status: "CLR",
        last_synced_at: 2.days.ago
      )
      Generators::Contention.build(
        claim_id: ep.claim_id,
        text: "Left knee"
      )

      intake = RampRefilingIntake.new(
        veteran_file_number: "12341234",
        user: current_user,
        detail: RampRefiling.new(
          veteran_file_number: "12341234"
        )
      )

      intake.start!

      visit "/intake"

      fill_in "What is the Receipt Date of this form?", with: "11/03/2017"
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Higher-Level Review", match: :prefer_exact).click
      end
      click_intake_continue

      expect(page).to have_content("Ineligible for Higher-Level Review")
      expect(page).to have_button("Continue to next step", disabled: true)
      click_on "Begin next intake"

      # Go back to start page
      expect(page).to have_content("Welcome to Caseflow Intake!")

      # Check there was an error in the DB
      intake.reload
      expect(intake.completion_status).to eq("error")
      expect(intake.error_code).to eq("ineligible_for_higher_level_review")
      expect(intake.detail).to be_nil
    end

    scenario "Review intake for RAMP Refiling form fails due to unexpected error" do
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             receipt_date: 4.days.ago,
                             established_at: 2.days.ago)

      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      EndProductEstablishment.create(
        source: ramp_election,
        veteran_file_number: "12341234",
        reference_id: ep.claim_id,
        synced_status: "CLR",
        last_synced_at: 2.days.ago
      )
      Generators::Contention.build(
        claim_id: ep.claim_id,
        text: "Left knee rating increase"
      )

      intake = RampRefilingIntake.new(veteran_file_number: "12341234", user: current_user)
      intake.start!

      visit "/intake"

      fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Higher-Level Review", match: :prefer_exact).click
      end

      expect_any_instance_of(RampRefilingIntake).to receive(:review!).and_raise("A random error. Oh no!")

      click_intake_continue

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/intake/review_request")
    end

    scenario "Complete a RAMP refiling for an appeal" do
      # Create an RAMP election with a cleared EP
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             receipt_date: 4.days.ago,
                             established_at: 2.days.ago)

      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      EndProductEstablishment.create(
        source: ramp_election,
        veteran_file_number: "12341234",
        reference_id: ep.claim_id,
        synced_status: "CLR",
        last_synced_at: 2.days.ago
      )

      Generators::Contention.build(
        claim_id: ep.claim_id,
        text: "Left knee rating increase"
      )

      Generators::Contention.build(
        claim_id: ep.claim_id,
        text: "Left shoulder service connection"
      )

      # Validate that you can't go directly to search
      visit "/intake/search"

      # Validate that you can't move forward without selecting a form
      scroll_element_in_to_view(".cf-submit.usa-button")
      expect(find(".cf-submit.usa-button")["disabled"]).to eq("true")

      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Selection (VA Form 21-4138)").click
      end
      safe_click ".cf-submit.usa-button"

      fill_in search_bar_title, with: "12341234"
      click_on "Search"

      expect(page).to have_current_path("/intake/review_request")

      # Validate issues have been created based on contentions
      expect(ramp_election.issues.count).to eq(2)

      # Validate validation
      fill_in "What is the Receipt Date of this form?", with: "11/02/2017"

      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Appeal to Board").click
      end

      click_intake_continue

      expect(page).to have_content(
        "Receipt date cannot be earlier than the original RAMP election receipt date of 12/03/2017"
      )

      fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
      click_intake_continue

      expect(page).to have_content("Please select an option")

      within_fieldset("Which type of appeal did the Veteran request?") do
        find("label", text: "Evidence Submission").click
      end

      click_intake_continue
      expect(page).to have_content("Finish processing RAMP Selection form")

      ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
      expect(ramp_refiling).to_not be_nil
      expect(ramp_refiling.option_selected).to eq("appeal")
      expect(ramp_refiling.appeal_docket).to eq("evidence_submission")
      expect(ramp_refiling.receipt_date).to eq(Date.new(2017, 12, 3))

      safe_click "#finish-intake"

      # Check that clicking next without confirmation throws an error
      expect(page).to have_content("Finish processing RAMP Selection form")
      expect(page).to have_content("You must confirm you've completed the steps")

      click_label("confirm-outside-caseflow-steps")

      safe_click "#finish-intake"

      # Check that clicking next without selecting a contention raises an error
      expect(page).to have_content("You must select at least one contention")

      find("label", text: "Left knee rating increase").click
      find("label", text: "Left shoulder service connection").click
      find("label", text: "The Veteran's form lists at least one ineligible contention").click

      safe_click "#finish-intake"

      expect(page).to have_content("Appeal record saved in Caseflow")
      expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
      expect(ramp_refiling.issues.count).to eq(2)
      expect(ramp_refiling.issues.first.description).to eq("Left knee rating increase")
      expect(ramp_refiling.issues.last.description).to eq("Left shoulder service connection")
      expect(ramp_refiling.issues.first.contention_reference_id).to be_nil
      expect(ramp_refiling.issues.last.contention_reference_id).to be_nil
    end

    scenario "Complete a RAMP Refiling for a supplemental claim" do
      # Create an complete Higher-Level Review RAMP election
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             option_selected: "higher_level_review_with_hearing",
                             receipt_date: 4.days.ago,
                             established_at: 2.days.ago)

      claim_id = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      ).claim_id

      EndProductEstablishment.create!(
        veteran_file_number: "12341234",
        source: ramp_election,
        established_at: 2.days.ago,
        last_synced_at: 2.days.ago,
        synced_status: "CLR",
        reference_id: claim_id
      )

      Generators::Contention.build(
        claim_id: claim_id,
        text: "Left knee rating increase"
      )

      intake = RampRefilingIntake.new(
        veteran_file_number: "12341234",
        user: current_user,
        detail: RampRefiling.new(
          veteran_file_number: "12341234"
        )
      )

      intake.start!

      Fakes::VBMSService.end_product_claim_id = "SHANE9123242"

      visit "/intake"

      fill_in "What is the Receipt Date of this form?", with: "12/07/2017"
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Supplemental Claim", match: :prefer_exact).click
      end
      click_intake_continue

      click_label("confirm-outside-caseflow-steps")
      find("label", text: "Left knee rating increase").click
      find("label", text: "The Veteran's form lists at least one ineligible contention").click

      Fakes::VBMSService.hold_request!
      expect(page).to have_button("Cancel intake", disabled: false)
      safe_click "#finish-intake"
      expect(page).to have_button("Cancel intake", disabled: true)

      Fakes::VBMSService.resume_request!

      expect(page).to have_content("Intake completed")

      ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
      expect(ramp_refiling.has_ineligible_issue).to eq(true)

      expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
        claim_hash: {
          benefit_type_code: "1",
          payee_code: "00",
          predischarge: false,
          claim_type: "Claim",
          station_of_jurisdiction: "397",
          date: ramp_refiling.receipt_date.to_date,
          end_product_modifier: "683",
          end_product_label: "Supplemental Claim Review Rating",
          end_product_code: "683SCRRRAMP",
          gulf_war_registry: false,
          suppress_acknowledgement_letter: false,
          claimant_participant_id: veteran.participant_id
        },
        veteran_hash: intake.veteran.to_vbms_hash,
        user: current_user
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: "12341234",
        claim_id: "SHANE9123242",
        contention_descriptions: ["Left knee rating increase"],
        user: current_user
      )

      expect(ramp_refiling.issues.count).to eq(1)
      expect(ramp_refiling.issues.first.contention_reference_id).to_not be_nil
      expect(page).to have_content(
        "Ed Merica's (ID #12341234) VA Form 21-4138 has been processed."
      )
      expect(page).to have_content(
        "Established EP: 683SCRRRAMP - Supplemental Claim Review Rating for Station 397"
      )
    end

    scenario "Complete a RAMP Refiling with only invalid issues" do
      # Create an complete Higher-Level Review RAMP election
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             option_selected: "higher_level_review_with_hearing",
                             receipt_date: 4.days.ago,
                             established_at: 2.days.ago)
      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      EndProductEstablishment.create(
        source: ramp_election,
        veteran_file_number: "12341234",
        reference_id: ep.claim_id,
        synced_status: "CLR",
        last_synced_at: 2.days.ago
      )
      Generators::Contention.build(
        claim_id: ep.claim_id,
        text: "Left knee rating increase"
      )

      intake = RampRefilingIntake.new(
        veteran_file_number: "12341234",
        user: current_user,
        detail: RampRefiling.new(
          veteran_file_number: "12341234"
        )
      )

      intake.start!

      visit "/intake"

      fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Supplemental Claim", match: :prefer_exact).click
      end
      click_intake_continue

      click_label("confirm-outside-caseflow-steps")
      find("label", text: "The Veteran's form lists at least one ineligible contention").click

      safe_click "#finish-intake"

      expect(page).to have_content("Ineligible RAMP request")

      ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
      expect(ramp_refiling.has_ineligible_issue).to eq(true)
      expect(ramp_refiling.issues.count).to eq(0)

      expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
      expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
    end

    scenario "Complete intake for RAMP Refiling fails due to duplicate EP" do
      allow(VBMSService).to receive(:establish_claim!).and_raise(ep_already_exists_error)

      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             receipt_date: 4.days.ago,
                             established_at: 2.days.ago)

      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      EndProductEstablishment.create(
        source: ramp_election,
        veteran_file_number: "12341234",
        reference_id: ep.claim_id,
        synced_status: "CLR",
        last_synced_at: 2.days.ago
      )
      Generators::Contention.build(
        claim_id: ep.claim_id,
        text: "Left knee rating increase"
      )

      visit "/intake/search"
      scroll_element_in_to_view(".cf-submit.usa-button")
      within_fieldset("Which form are you processing?") do
        find("label", text: "RAMP Selection (VA Form 21-4138)").click
      end
      safe_click ".cf-submit.usa-button"
      fill_in search_bar_title, with: "12341234"
      click_on "Search"
      fill_in "What is the Receipt Date of this form?", with: "12/03/2017"
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Higher-Level Review", match: :prefer_exact).click
      end
      click_intake_continue
      click_label("confirm-outside-caseflow-steps")
      find("label", text: "Left knee rating increase").click
      find("label", text: "The Veteran's form lists at least one ineligible contention").click
      safe_click "#finish-intake"

      expect(page).to have_content("An EP 682 for this Veteran's claim was created outside Caseflow.")
    end
  end
end
