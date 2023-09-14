# frozen_string_literal: true

RSpec.feature "RAMP Refiling Intake", :postgres do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ramp_start_date)

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
    let(:receipt_date) { 4.days.ago.to_date }

    scenario "Start a RAMP refiling with an invalid option" do
      # Create an complete Higher-Level Review RAMP election
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             option_selected: "higher_level_review_with_hearing",
                             receipt_date: receipt_date,
                             established_at: 2.days.ago)
      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      create(
        :end_product_establishment,
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

      fill_in "What is the Receipt Date of this form?", with: ramp_start_date.to_date.mdY
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Higher-Level Review", match: :prefer_exact).click
      end
      click_intake_continue

      expect(page).to have_content("Ineligible for Higher-Level Review")
      expect(page).to have_content(COPY::INELIGIBLE_HIGHER_LEVEL_REVIEW_ALERT)
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
                             receipt_date: receipt_date,
                             established_at: 2.days.ago)

      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      create(
        :end_product_establishment,
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

      fill_in "What is the Receipt Date of this form?", with: receipt_date.mdY
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Higher-Level Review", match: :prefer_exact).click
      end

      expect_any_instance_of(RampRefilingIntake).to receive(:review!).and_raise("A random error. Oh no!")

      click_intake_continue

      expect(page).to have_content("Something went wrong")
      expect(page).to have_current_path("/intake/review_request")
    end

    scenario "Complete a RAMP Refiling for a supplemental claim" do
      # Create an complete Higher-Level Review RAMP election
      ramp_election = create(:ramp_election,
                             veteran_file_number: "12341234",
                             notice_date: 5.days.ago,
                             option_selected: "higher_level_review_with_hearing",
                             receipt_date: receipt_date,
                             established_at: 2.days.ago)

      claim_id = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      ).claim_id

      create(
        :end_product_establishment,
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

      fill_in "What is the Receipt Date of this form?", with: Time.zone.yesterday.mdY
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

      expect(page).to have_content(COPY::RAMP_COMPLETED_ALERT)

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
          claimant_participant_id: veteran.participant_id,
          limited_poa_code: nil,
          limited_poa_access: nil,
          status_type_code: "PEND"
        },
        veteran_hash: intake.veteran.to_vbms_hash,
        user: current_user
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: "12341234",
        claim_id: "SHANE9123242",
        contentions: [{ description: "Left knee rating increase" }],
        user: current_user,
        claim_date: ramp_refiling.receipt_date.to_date
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
                             receipt_date: receipt_date,
                             established_at: 2.days.ago)
      ep = Generators::EndProduct.build(
        veteran_file_number: "12341234",
        bgs_attrs: { status_type_code: "CLR" }
      )
      create(
        :end_product_establishment,
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

      fill_in "What is the Receipt Date of this form?", with: receipt_date.mdY
      within_fieldset("Which review lane did the Veteran select?") do
        find("label", text: "Supplemental Claim", match: :prefer_exact).click
      end
      click_intake_continue

      click_label("confirm-outside-caseflow-steps")
      find("label", text: "The Veteran's form lists at least one ineligible contention").click

      safe_click "#finish-intake"

      expect(page).to have_content("Ineligible RAMP request")

      expect(page).to have_content(COPY::INELIGIBLE_RAMP_ALERT)

      ramp_refiling = RampRefiling.find_by(veteran_file_number: "12341234")
      expect(ramp_refiling.has_ineligible_issue).to eq(true)
      expect(ramp_refiling.issues.count).to eq(0)

      expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
      expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
    end
  end
end
