# frozen_string_literal: true

feature "RAMP Election Intake", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ramp_start_date)

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    FeatureToggle.enable!(:ramp_intake)
  end

  after { FeatureToggle.disable!(:ramp_intake) }

  let!(:veteran) do
    Generators::Veteran.build(file_number: "12341234", first_name: "Ed", last_name: "Merica")
  end

  let!(:other_veterans) do
    Generators::Veteran.build(file_number: "77776666")
    Generators::Veteran.build(file_number: "77778888")
  end

  let!(:vacols_case) do
    create(
      :case,
      :status_advance,
      bfcorlid: "12341234C",
      case_issues: [create(:case_issue, :compensation, issdesc: "Broken thigh")],
      bfdnod: 1.year.ago
    )
  end

  let!(:inactive_appeal) do
    create(
      :case,
      :status_complete,
      bfcorlid: "77776666C",
      bfdnod: 1.year.ago
    )
  end

  let!(:ineligible_appeal) do
    create(
      :case,
      :status_active,
      bfcorlid: "77778888C",
      case_issues: [create(:case_issue, :compensation)],
      bfdnod: 1.year.ago
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

  scenario "Search for a veteran with an no active appeals" do
    create(:ramp_election, veteran_file_number: "77776666", notice_date: 5.days.ago)
    visit "/intake"
    select_form(Constants.INTAKE_FORM_NAMES.ramp_election)
    safe_click ".cf-submit.usa-button"
    fill_in search_bar_title, with: "77776666"
    click_on "Search"

    expect(page).to have_current_path("/intake/search")
    expect(page).to have_content("Ineligible to participate in RAMP: no active appeals")
  end

  scenario "Search for a veteran with an ineligible appeal" do
    create(:ramp_election, veteran_file_number: "77778888", notice_date: 5.days.ago)
    visit "/intake"
    select_form(Constants.INTAKE_FORM_NAMES.ramp_election)
    safe_click ".cf-submit.usa-button"
    fill_in search_bar_title, with: "77778888"
    click_on "Search"

    expect(page).to have_current_path("/intake/search")
    expect(page).to have_content("Ineligible to participate in RAMP")
  end

  scenario "Search for a veteran already in progress by current user" do
    visit "/intake"
    select_form(Constants.INTAKE_FORM_NAMES.ramp_election)
    safe_click ".cf-submit.usa-button"

    RampElectionIntake.new(
      user: current_user,
      veteran_file_number: "43214321"
    ).start!

    fill_in search_bar_title, with: "12341234"
    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")
    expect(page).to have_content("Review Ed Merica's Opt-In Election Form")
  end

  scenario "Search for a veteran that has received a RAMP election" do
    create(:ramp_election, veteran_file_number: "12341234", notice_date: 5.days.ago)

    # Validate you're redirected back to the search page if you haven't started yet
    visit "/intake/completed"
    expect(page).to have_content("Welcome to Caseflow Intake!")

    visit "/intake/review_request"
    select_form(Constants.INTAKE_FORM_NAMES.ramp_election)
    safe_click ".cf-submit.usa-button"

    fill_in search_bar_title, with: "12341234"
    click_on "Search"

    expect(page).to have_current_path("/intake/review_request")
    expect(page).to have_content("Review Ed Merica's Opt-In Election Form")

    intake = RampElectionIntake.find_by(veteran_file_number: "12341234")
    expect(intake).to_not be_nil
    expect(intake.started_at).to eq(Time.zone.now)
    expect(intake.user).to eq(current_user)
  end

  scenario "Start intake and go back and edit option" do
    create(:ramp_election, veteran_file_number: "12341234", notice_date: post_ramp_start_date.to_date)
    intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
    intake.start!

    # Validate that visiting the finish page takes you back to
    # the review request page if you haven't yet reviewed the intake
    visit "/intake/completed"

    # Validate validation
    fill_in "What is the Receipt Date of this form?", with: pre_ramp_start_date.to_date.mdY
    click_intake_continue

    expect(page).to have_content("Please select an option.")
    expect(page).to have_content(
      "Receipt Date cannot be earlier than RAMP start date, 11/01/2017"
    )

    within_fieldset("Which review lane did the Veteran select?") do
      find("label", text: "Higher-Level Review", match: :prefer_exact).click
    end
    fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY
    click_intake_continue

    expect(page).to have_content("Finish processing Higher-Level Review election")

    click_label "confirm-finish"

    ## Validate error message when complete intake fails
    allow(LegacyAppeal).to receive(:close).and_raise("A random error. Oh no!")

    safe_click "button#button-submit-review"
    expect(page).to have_content("Something went wrong")

    page.go_back

    expect(page).to_not have_content("Please select an option.")

    within_fieldset("Which review lane did the Veteran select?") do
      find("label", text: "Supplemental Claim").click
    end
    click_intake_continue

    expect(find("#confirm-finish", visible: false)).to_not be_checked
    expect(page).to_not have_content("Something went wrong")

    expect(page).to have_content("Finish processing Supplemental Claim election")

    # Validate the appeal & issue also shows up
    expect(page).to have_content("This Veteran has 1 eligible appeal, with the following issues")
    expect(page).to have_content("5252 - Thigh, limitation of flexion of")
    expect(page).to have_content("Broken thigh")
  end

  scenario "Review intake for RAMP Election form fails due to unexpected error" do
    create(:ramp_election, veteran_file_number: "12341234", notice_date: post_ramp_start_date.to_date)

    intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
    intake.start!

    visit "/intake"

    within_fieldset("Which review lane did the Veteran select?") do
      find("label", text: "Higher-Level Review with Informal Conference").click
    end

    fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY
    expect_any_instance_of(RampElectionIntake).to receive(:review!).and_raise("A random error. Oh no!")

    click_intake_continue

    expect(page).to have_content("Something went wrong")
    expect(page).to have_current_path("/intake/review_request")
  end

  scenario "Complete intake for RAMP Election form" do
    Fakes::VBMSService.end_product_claim_id = "SHANE9642"

    intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
    intake.start!

    # Validate that visiting the finish page takes you back to
    # the review request page if you haven't yet reviewed the intake
    visit "/intake/completed"

    within_fieldset("Which review lane did the Veteran select?") do
      find("label", text: "Higher-Level Review with Informal Conference").click
    end

    fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY
    click_intake_continue

    expect(page).to have_content("Finish processing Higher-Level Review election")

    election = RampElection.find_by(veteran_file_number: "12341234")
    expect(election.option_selected).to eq("higher_level_review_with_hearing")
    expect(election.receipt_date).to eq(Time.zone.today)

    # Validate the app redirects you to the appropriate location
    visit "/intake"
    click_intake_continue
    expect(page).to have_content("Finish processing Higher-Level Review election")

    expect(AppealRepository).to receive(:close_undecided_appeal!).with(
      appeal: LegacyAppeal.find_or_create_by_vacols_id(vacols_case.bfkey),
      user: current_user,
      closed_on: Time.zone.now,
      disposition_code: "P"
    )

    safe_click "button#button-submit-review"

    expect(page).to have_content("You must confirm you've completed the steps")
    expect(page).to_not have_content("Intake completed")
    expect(page).to have_button("Cancel intake", disabled: false)
    click_label("confirm-finish")

    Fakes::VBMSService.hold_request!
    safe_click "button#button-submit-review"

    expect(page).to have_button("Cancel intake", disabled: true)

    Fakes::VBMSService.resume_request!

    expect(page).to have_content("Intake completed")
    expect(page).to have_content(
      "Established EP: 682HLRRRAMP - Higher-Level Review Rating for Station 397"
    )

    expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
      claim_hash: {
        benefit_type_code: "1",
        payee_code: "00",
        predischarge: false,
        claim_type: "Claim",
        station_of_jurisdiction: "397",
        date: election.receipt_date.to_date,
        end_product_modifier: "682",
        end_product_label: "Higher-Level Review Rating",
        end_product_code: "682HLRRRAMP",
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

    # Validate that you can not go back to previous steps
    page.go_back
    expect(page).to have_content("Intake completed")

    page.go_back
    page.go_back
    expect(page).to have_content("Welcome to Caseflow Intake!")

    intake.reload
    expect(intake.completed_at).to eq(Time.zone.now)
    expect(intake).to be_success

    resultant_end_product_establishment = EndProductEstablishment.find_by(source: election.reload)
    expect(resultant_end_product_establishment.reference_id).to eq("SHANE9642")

    # Validate that the intake is no longer able to be worked on
    visit "/intake/finish"
    expect(page).to have_content("Welcome to Caseflow Intake!")
  end

  scenario "Complete intake for RAMP Election form fails due to duplicate EP" do
    allow(VBMSService).to receive(:establish_claim!).and_raise(ep_already_exists_error)

    create(:ramp_election, veteran_file_number: "12341234", notice_date: post_ramp_start_date.to_date)

    intake = RampElectionIntake.new(veteran_file_number: "12341234", user: current_user)
    intake.start!

    visit "/intake"

    within_fieldset("Which review lane did the Veteran select?") do
      find("label", text: "Higher-Level Review with Informal Conference").click
    end

    fill_in "What is the Receipt Date of this form?", with: Time.zone.today.mdY
    click_intake_continue

    expect(page).to have_content("Finish processing Higher-Level Review election")

    click_label("confirm-finish")
    safe_click "button#button-submit-review"

    expect(page).to have_content("An EP 682 for this Veteran's claim was created outside Caseflow.")
  end
end
