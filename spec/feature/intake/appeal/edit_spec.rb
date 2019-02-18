require "support/intake_helpers"

feature "Appeal Edit issues" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Timecop.freeze(post_ama_start_date)

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
  end

  after do
    FeatureToggle.disable!(:intakeAma)
    FeatureToggle.disable!(:intake_legacy_opt_in)
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:receipt_date) { Time.zone.today - 20.days }
  let(:profile_date) { receipt_date - 30.days }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted", contention_reference_id: 55 },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "abcdef", decision_text: "Back pain" }
      ]
    )
  end

  let!(:rating_before_ama) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: DecisionReview.ama_activation_date - 5.days,
      profile_date: DecisionReview.ama_activation_date - 10.days,
      issues: [
        { reference_id: "before_ama_ref_id", decision_text: "Non-RAMP Issue before AMA Activation" }
      ]
    )
  end

  let!(:rating_before_ama_from_ramp) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: DecisionReview.ama_activation_date - 5.days,
      profile_date: DecisionReview.ama_activation_date - 11.days,
      issues: [
        { decision_text: "Issue before AMA Activation from RAMP",
          reference_id: "ramp_ref_id" }
      ],
      associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" }
    )
  end

  let!(:ratings_with_legacy_issues) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date - 4.days,
      profile_date: receipt_date - 4.days,
      issues: [
        { reference_id: "has_legacy_issue", decision_text: "Issue with legacy issue not withdrawn" },
        { reference_id: "has_ineligible_legacy_appeal", decision_text: "Issue connected to ineligible legacy appeal" }
      ]
    )
  end

  let(:legacy_opt_in_approved) { false }
  let!(:appeal) do
    create(:appeal,
           veteran_file_number: veteran.file_number,
           receipt_date: receipt_date,
           docket_type: "evidence_submission",
           veteran_is_not_claimant: false,
           legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
  end

  let(:nonrating_request_issue_attributes) do
    {
      decision_review: appeal,
      issue_category: "Military Retired Pay",
      nonrating_issue_description: "nonrating description",
      contention_reference_id: "1234",
      decision_date: 1.month.ago
    }
  end

  let!(:nonrating_request_issue) { create(:request_issue, nonrating_request_issue_attributes) }

  let(:rating_request_issue_attributes) do
    {
      decision_review: appeal,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: profile_date,
      contested_issue_description: "PTSD denied",
      contention_reference_id: "4567"
    }
  end

  let!(:rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }

  scenario "allows adding/removing issues" do
    visit "appeals/#{appeal.uuid}/edit/"

    expect(page).to have_content(nonrating_request_issue.description)

    # remove an issue
    nonrating_intake_num = find_intake_issue_number_by_text(nonrating_request_issue.issue_category)
    click_remove_intake_issue(nonrating_intake_num)
    click_remove_issue_confirmation
    expect(page).not_to have_content(nonrating_request_issue.description)

    # add a different issue
    click_intake_add_issue
    add_intake_rating_issue("Left knee granted")

    # save
    expect(page).to have_content("Left knee granted")
    safe_click("#button-submit-update")

    # should redirect to queue
    expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

    # going back to edit page should show those issues
    visit "appeals/#{appeal.uuid}/edit/"
    expect(page).to have_content("Left knee granted")
    expect(page).not_to have_content("nonrating description")

    # canceling should redirect to queue
    click_on "Cancel"
    expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
  end

  scenario "allows removing and re-adding same issue" do
    issue_description = rating_request_issue.description

    visit "appeals/#{appeal.uuid}/edit/"

    expect(page).to have_content(issue_description)
    expect(page).to have_button("Save", disabled: true)

    # remove
    issue_num = find_intake_issue_number_by_text(issue_description)
    click_remove_intake_issue(issue_num)
    click_remove_issue_confirmation
    expect(page).not_to have_content(issue_description)

    # re-add
    click_intake_add_issue
    add_intake_rating_issue(issue_description, "a new comment")
    expect(page).to have_content(issue_description)
    expect(page).to_not have_content(
      Constants.INELIGIBLE_REQUEST_ISSUES.duplicate_of_rating_issue_in_active_review.gsub("{review_title}", "Appeal")
    )

    # issue note was added
    expect(page).to have_button("Save", disabled: false)
  end

  context "ratings with disabiliity codes" do
    let(:disabiliity_receive_date) { receipt_date - 1.day }
    let(:disability_profile_date) { receipt_date - 10.days }
    let!(:ratings_with_diagnostic_codes) do
      generate_ratings_with_disabilities(
        veteran,
        disabiliity_receive_date,
        disability_profile_date
      )
    end

    scenario "saves diagnostic codes" do
      visit "appeals/#{appeal.uuid}/edit/"

      save_and_check_request_issues_with_diagnostic_codes(
        Constants.INTAKE_FORM_NAMES.appeal,
        appeal
      )
    end
  end

  context "with multiple request issues with same data fields" do
    let!(:duplicate_nonrating_request_issue) { create(:request_issue, nonrating_request_issue_attributes) }
    let!(:duplicate_rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }

    scenario "saves by id" do
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content(duplicate_nonrating_request_issue.description, count: 2)
      expect(page).to have_content(duplicate_rating_request_issue.description, count: 2)

      # add another new issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "A description!",
        date: profile_date.mdY
      )

      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      request_issue_update = RequestIssuesUpdate.where(review: appeal).last
      non_modified_ids = [duplicate_nonrating_request_issue.id, duplicate_rating_request_issue.id,
                          nonrating_request_issue.id, rating_request_issue.id]

      # duplicate issues should be neither added nor removed
      expect(request_issue_update.created_issues.map(&:id)).to_not include(non_modified_ids)
      expect(request_issue_update.removed_issues.map(&:id)).to_not include(non_modified_ids)
    end
  end

  context "with legacy appeals" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
    end

    context "with legacy_opt_in_approved" do
      let(:legacy_opt_in_approved) { true }
      scenario "adding issues" do
        visit "appeals/#{appeal.uuid}/edit/"

        click_intake_add_issue
        expect(page).to have_content("Next")
        add_intake_rating_issue("Left knee granted")

        # expect legacy opt in modal
        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

        add_intake_rating_issue("intervertebral disc syndrome") # ineligible issue

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
        )

        click_intake_add_issue
        add_intake_rating_issue("Back pain")
        add_intake_rating_issue("ankylosis of hip") # eligible issue

        safe_click("#button-submit-update")
        safe_click ".confirm"

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        expect(RequestIssue.find_by(
                 contested_issue_description: "Left knee granted",
                 ineligible_reason: :legacy_appeal_not_eligible,
                 vacols_id: "vacols2",
                 vacols_sequence_id: "1"
               )).to_not be_nil

        ri_with_optin = RequestIssue.find_by(
          contested_issue_description: "Back pain",
          ineligible_reason: nil,
          vacols_id: "vacols1",
          vacols_sequence_id: "1"
        )

        expect(ri_with_optin).to_not be_nil
        li_optin = ri_with_optin.legacy_issue_optin
        expect(li_optin.optin_processed_at).to_not be_nil
        expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
          LegacyIssueOptin::VACOLS_DISPOSITION_CODE
        )

        # Check rollback
        visit "appeals/#{appeal.uuid}/edit/"
        click_remove_intake_issue_by_text("Back pain")
        click_remove_issue_confirmation
        safe_click("#button-submit-update")
        safe_click ".confirm"

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
        expect(li_optin.reload.rollback_processed_at).to_not be_nil
        expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
          li_optin.original_disposition_code
        )
      end
    end

    context "with legacy opt in not approved" do
      let(:legacy_opt_in_approved) { false }
      scenario "adding issues" do
        visit "appeals/#{appeal.uuid}/edit/"
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")
        # do not show inactive appeals when legacy opt in is false
        expect(page).to_not have_content("impairment of hip")
        expect(page).to_not have_content("typhoid arthritis")

        add_intake_rating_issue("ankylosis of hip")

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
        )

        safe_click("#button-submit-update")
        safe_click ".confirm"

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        expect(RequestIssue.find_by(
                 contested_issue_description: "Left knee granted",
                 ineligible_reason: :legacy_issue_not_withdrawn,
                 vacols_id: "vacols1",
                 vacols_sequence_id: "1"
               )).to_not be_nil
      end
    end

    scenario "adding issue with legacy opt in disabled" do
      allow(FeatureToggle).to receive(:enabled?).and_call_original
      allow(FeatureToggle).to receive(:enabled?).with(:intake_legacy_opt_in, user: current_user).and_return(false)

      visit "appeals/#{appeal.uuid}/edit/"

      click_intake_add_issue
      expect(page).to have_content("Add this issue")
      add_intake_rating_issue("Left knee granted")
      expect(page).to have_content("Left knee granted")
    end
  end

  context "appeal is outcoded" do
    let(:appeal) { create(:appeal, :outcoded, veteran: veteran) }

    scenario "error message is shown and no edit is allowed" do
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_current_path("/appeals/#{appeal.uuid}/edit/outcoded")
      expect(page).to have_content("Issues Not Editable")
      expect(page).to have_content("This appeal has been outcoded and the issues are no longer editable.")
    end
  end
end
