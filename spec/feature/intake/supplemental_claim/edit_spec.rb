require "support/intake_helpers"

feature "Supplemental Claim Edit issues" do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))

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

  let(:receipt_date) { Time.zone.today - 20 }
  let(:profile_date) { "2017-11-02T07:00:00.000Z" }

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

  let(:is_dta_error) { false }
  let(:benefit_type) { "compensation" }

  let!(:supplemental_claim) do
    SupplementalClaim.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      is_dta_error: is_dta_error,
      veteran_is_not_claimant: true
    )
  end

  # create intake
  let!(:intake) do
    Intake.create!(
      user_id: current_user.id,
      detail: supplemental_claim,
      veteran_file_number: veteran.file_number,
      started_at: Time.zone.now,
      completed_at: Time.zone.now,
      completion_status: "success",
      type: "SupplementalClaimIntake"
    )
  end

  let(:rating_ep_claim_id) do
    EndProductEstablishment.find_by(
      source: supplemental_claim,
      code: "040SCR"
    ).reference_id
  end

  before do
    supplemental_claim.create_claimants!(participant_id: "5382910292", payee_code: "10")

    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original

    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
      first_name: "BOB",
      last_name: "VANCE",
      ptcpnt_id: "5382910292",
      relationship_type: "Spouse"
    )
  end

  context "when there is a non-rating end product" do
    let!(:nonrating_request_issue) do
      RequestIssue.create!(
        review_request: supplemental_claim,
        issue_category: "Military Retired Pay",
        nonrating_issue_description: "nonrating description",
        contention_reference_id: "1234",
        benefit_type: "compensation",
        decision_date: 1.month.ago
      )
    end

    before do
      supplemental_claim.create_issues!([nonrating_request_issue])
      supplemental_claim.establish!
    end

    context "when it is created due to a DTA error" do
      let(:is_dta_error) { true }

      it "cannot be edited" do
        nonrating_dta_claim_id = EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040HDENR"
        ).reference_id

        visit "supplemental_claims/#{nonrating_dta_claim_id}/edit"
        expect(page).to have_content("Issues Not Editable")
      end

      context "when benefit type is pension" do
        let(:benefit_type) { "pension" }
        it "cannot be edited" do
          nonrating_dta_claim_id = EndProductEstablishment.find_by(
            source: supplemental_claim,
            code: "040HDENRPMC"
          ).reference_id

          visit "supplemental_claims/#{nonrating_dta_claim_id}/edit"
          expect(page).to have_content("Issues Not Editable")
        end
      end
    end

    it "shows the Supplemental Claim Edit page with a nonrating claim id" do
      nonrating_ep_claim_id = EndProductEstablishment.find_by(
        source: supplemental_claim,
        code: "040SCNR"
      ).reference_id
      visit "supplemental_claims/#{nonrating_ep_claim_id}/edit"

      expect(page).to have_content("Military Retired Pay")

      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "A description!",
        date: "04/25/2018"
      )

      safe_click("#button-submit-update")

      expect(page).to have_content("The review originally had 1 issue but now has 2.")
      safe_click ".confirm"

      expect(page).to have_current_path(
        "/supplemental_claims/#{nonrating_ep_claim_id}/edit/confirmation"
      )
    end
  end

  context "when there is a rating end product" do
    let(:request_issue) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        review_request: supplemental_claim,
        benefit_type: "compensation",
        contested_issue_description: "PTSD denied"
      )
    end

    let(:request_issues) { [request_issue] }

    before do
      supplemental_claim.create_issues!(request_issues)
      supplemental_claim.establish!
    end

    context "when it is created due to a DTA error" do
      let(:is_dta_error) { true }

      it "cannot be edited" do
        rating_dta_claim_id = EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040HDER"
        ).reference_id

        visit "supplemental_claims/#{rating_dta_claim_id}/edit"
        expect(page).to have_content("Issues Not Editable")
      end

      context "when benefit type is pension" do
        let(:benefit_type) { "pension" }
        it "cannot be edited" do
          rating_dta_claim_id = EndProductEstablishment.find_by(
            source: supplemental_claim,
            code: "040HDERPMC"
          ).reference_id

          visit "supplemental_claims/#{rating_dta_claim_id}/edit"
          expect(page).to have_content("Issues Not Editable")
        end
      end
    end

    it "shows request issues and allows adding/removing issues" do
      visit "supplemental_claims/#{rating_ep_claim_id}/edit"

      # Check that request issues appear correctly as added issues
      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      expect(page).to have_content("Add / Remove Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.supplemental_claim)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

      click_intake_add_issue

      expect(page).to have_content("Add issue 2")
      expect(page).to have_content("Does issue 2 match any of these issues")
      expect(page).to have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      # test canceling adding an issue by closing the modal
      safe_click ".close-modal"
      expect(page).to_not have_content("2. Left knee granted")

      # adding an issue should show the issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_content("2. Left knee granted")
      expect(page).to_not have_content("Notes:")
      click_remove_intake_issue("1")

      # expect a pop up
      expect(page).to have_content("Are you sure you want to remove this issue?")
      click_remove_issue_confirmation

      expect(page).not_to have_content("PTSD denied")

      # re-add to proceed
      click_intake_add_issue
      add_intake_rating_issue("PTSD denied", "I am an issue note")
      expect(page).to have_content("2. PTSD denied")
      expect(page).to have_content("I am an issue note")

      # clicking add issue again should show a disabled radio button for that same rating
      click_intake_add_issue
      expect(page).to have_content("Add issue 3")
      expect(page).to have_content("Does issue 3 match any of these issues")
      expect(page).to have_content("Left knee granted (already selected for issue 1)")
      expect(page).to have_css("input[disabled]", visible: false)

      # Add nonrating issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: "04/25/2018"
      )
      expect(page).to have_content("3 issues")

      # add unidentified issue
      click_intake_add_issue
      add_intake_unidentified_issue("This is an unidentified issue")
      expect(page).to have_content("4 issues")
      expect(page).to have_content("This is an unidentified issue")
    end

    context "when veteran has active nonrating request issues" do
      let(:another_higher_level_review) do
        create(:higher_level_review,
               veteran_file_number: veteran.file_number,
               benefit_type: "compensation")
      end

      let!(:active_nonrating_request_issue) do
        create(:request_issue,
               :nonrating,
               review_request: another_higher_level_review)
      end

      before do
        another_higher_level_review.create_issues!([active_nonrating_request_issue])
      end

      scenario "shows ineligibility message and saves conflicting request issue id" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        click_intake_add_issue
        click_intake_no_matching_issues

        fill_in "Issue category", with: active_nonrating_request_issue.issue_category
        find("#issue-category").send_keys :enter
        expect(page).to have_content("Does issue 2 match any of the issues actively being reviewed?")
        expect(page).to have_content("#{active_nonrating_request_issue.issue_category}: " \
                                     "#{active_nonrating_request_issue.description}")
        add_active_intake_nonrating_issue(active_nonrating_request_issue.issue_category)
        expect(page).to have_content("#{active_nonrating_request_issue.issue_category} -" \
                                     " #{active_nonrating_request_issue.description}" \
                                     " is ineligible because it's already under review as a Higher-Level Review")

        safe_click("#button-submit-update")
        safe_click ".confirm"
        expect(page).to have_current_path(
          "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
        )

        expect(
          RequestIssue.find_by(
            review_request: supplemental_claim,
            issue_category: active_nonrating_request_issue.issue_category,
            ineligible_due_to: active_nonrating_request_issue.id,
            ineligible_reason: "duplicate_of_nonrating_issue_in_active_review",
            nonrating_issue_description: active_nonrating_request_issue.description,
            decision_date: active_nonrating_request_issue.decision_date
          )
        ).to_not be_nil
      end
    end

    context "has decision issues" do
      let(:contested_decision_issues) { setup_prior_decision_issues(veteran) }
      let(:decision_request_issue) do
        create(
          :request_issue,
          review_request: supplemental_claim,
          contested_issue_description: "currently contesting decision issue",
          decision_date: Time.zone.now - 2.days,
          contested_decision_issue_id: contested_decision_issues.first.id
        )
      end

      let(:request_issues) { [request_issue, decision_request_issue] }

      let!(:request_issue_that_causes_ineligiblity) do
        already_active_hlr = create(:higher_level_review, :with_end_product_establishment)
        create(
          :request_issue,
          review_request: already_active_hlr,
          contested_issue_description: "currently active request issue",
          decision_date: Time.zone.now - 2.days,
          end_product_establishment_id: already_active_hlr.end_product_establishments.first.id,
          contested_decision_issue_id: contested_decision_issues.second.id
        )
      end

      it "shows decision isssues and allows adding/removing issues" do
        verify_decision_issues_can_be_added_and_removed(
          "supplemental_claims/#{rating_ep_claim_id}/edit",
          decision_request_issue,
          supplemental_claim,
          contested_decision_issues
        )
      end
    end

    context "with existing request issues contesting decision issues" do
      let(:decision_request_issue) do
        setup_request_issue_with_nonrating_decision_issue(supplemental_claim)
      end

      let(:nonrating_decision_request_issue) do
        setup_request_issue_with_rating_decision_issue(
          supplemental_claim,
          contested_rating_issue_reference_id: "abc123"
        )
      end

      let(:request_issues) { [request_issue, decision_request_issue, nonrating_decision_request_issue] }

      it "does not remove & readd unedited issues" do
        verify_request_issue_contending_decision_issue_not_readded(
          "supplemental_claims/#{rating_ep_claim_id}/edit",
          supplemental_claim,
          decision_request_issue.decision_issues + nonrating_decision_request_issue.decision_issues
        )
      end
    end

    it "enables save button only when dirty" do
      visit "supplemental_claims/#{rating_ep_claim_id}/edit"

      expect(page).to have_button("Save", disabled: true)

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      click_remove_intake_issue("2")
      click_remove_issue_confirmation

      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_button("Save", disabled: true)
    end

    it "Does not allow save if no issues are selected" do
      visit "supplemental_claims/#{rating_ep_claim_id}/edit"
      click_remove_intake_issue("1")
      click_remove_issue_confirmation

      expect(page).to have_button("Save", disabled: true)
    end

    scenario "shows error message if an update is in progress" do
      RequestIssuesUpdate.create!(
        review: supplemental_claim,
        user: current_user,
        before_request_issue_ids: [request_issue.id],
        after_request_issue_ids: [request_issue.id],
        attempted_at: Time.zone.now,
        submitted_at: Time.zone.now,
        processed_at: nil
      )

      visit "supplemental_claims/#{rating_ep_claim_id}/edit"
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      safe_click("#button-submit-update")

      expect(page).to have_content("The review originally had 1 issue but now has 2.")
      safe_click ".confirm"

      expect(page).to have_content("Previous update not yet done processing")
    end

    it "updates selected issues" do
      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

      visit "supplemental_claims/#{rating_ep_claim_id}/edit"
      click_remove_intake_issue("1")
      click_remove_issue_confirmation
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")

      expect(page).to have_current_path(
        "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
      )

      # reload to verify that the new issues populate the form
      visit "supplemental_claims/#{rating_ep_claim_id}/edit"
      expect(page).to have_content("Left knee granted")
      expect(page).to_not have_content("PTSD denied")

      # assert server has updated data
      new_request_issue = supplemental_claim.reload.request_issues.first
      expect(new_request_issue.description).to eq("Left knee granted")
      expect(request_issue.reload.review_request_id).to be_nil
      expect(request_issue.removed_at).to eq(Time.zone.now)
      expect(new_request_issue.rating_issue_associated_at).to eq(Time.zone.now)

      # expect contentions to reflect issue update
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: veteran.file_number,
        claim_id: rating_ep_claim_id,
        contention_descriptions: ["Left knee granted"],
        special_issues: [],
        user: current_user
      )
      expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
        claim_id: rating_ep_claim_id,
        rating_issue_contention_map: {
          new_request_issue.contested_rating_issue_reference_id => new_request_issue.contention_reference_id
        }
      )
      expect(Fakes::VBMSService).to have_received(:remove_contention!).once
    end

    feature "cancel edits" do
      def click_cancel(visit_page)
        visit "supplemental_claims/#{rating_ep_claim_id}/edit#{visit_page}"
        click_on "Cancel"
        correct_path = "/supplemental_claims/#{rating_ep_claim_id}/edit/cancel"
        expect(page).to have_current_path(correct_path)
        expect(page).to have_content("Edit Canceled")
        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
      end

      scenario "from landing page" do
        click_cancel("/")
      end
    end

    feature "with cleared end product" do
      let!(:cleared_end_product) do
        create(:end_product_establishment,
               source: supplemental_claim,
               synced_status: "CLR")
      end

      scenario "prevents edits on eps that have cleared" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"
        expect(page).to have_current_path("/supplemental_claims/#{rating_ep_claim_id}/edit/cleared_eps")
        expect(page).to have_content("Issues Not Editable")
        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
      end
    end
  end
end
