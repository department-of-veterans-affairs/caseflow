# frozen_string_literal: true

feature "Supplemental Claim Edit issues", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)
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
  let(:profile_date) { (Time.zone.today - 60).to_datetime }

  let!(:rating) { generate_rating_with_defined_contention(veteran, receipt_date, profile_date) }
  let!(:rating_before_ama) { generate_pre_ama_rating(veteran) }
  let!(:rating_before_ama_from_ramp) { generate_rating_before_ama_from_ramp(veteran) }
  let!(:ratings_with_legacy_issues) do
    generate_rating_with_legacy_issues(veteran, receipt_date - 4.days, receipt_date - 4.days)
  end
  let!(:rating_with_old_decisions) { generate_rating_with_old_decisions(veteran, receipt_date) }
  let(:request_issue_decision_mdY) { request_issue.decision_or_promulgation_date.mdY }
  let(:old_rating_decision_text) { "Bone (Right arm broken) is denied." }

  let(:decision_review_remanded) { nil }
  let(:benefit_type) { "compensation" }

  let!(:supplemental_claim) do
    SupplementalClaim.create!(
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      decision_review_remanded: decision_review_remanded,
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

  let(:contested_decision_issue) { nil }

  before do
    supplemental_claim.create_claimant!(participant_id: "5382910292", payee_code: "10", type: "DependentClaimant")

    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original

    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
      first_name: "BOB",
      last_name: "VANCE",
      ptcpnt_id: "5382910292",
      relationship_type: "Spouse"
    )
  end

  context "when contentions disappear from VBMS between creation and edit" do
    let(:request_issue) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_review: supplemental_claim,
        benefit_type: benefit_type,
        contested_issue_description: "PTSD denied"
      )
    end

    before do
      supplemental_claim.create_issues!([request_issue])
      supplemental_claim.establish!
      supplemental_claim.reload
      request_issue.reload
      Fakes::VBMSService.remove_contention!(request_issue.contention)
    end

    it "automatically removes issues" do
      visit "supplemental_claims/#{supplemental_claim.uuid}/edit"

      expect(page).to_not have_content("PTSD denied")
      expect(request_issue.reload).to be_closed
    end
  end

  context "when the rating issue is locked" do
    let(:url_path) { "supplemental_claims" }
    let(:decision_review) { supplemental_claim }
    let(:request_issue) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_review: decision_review,
        benefit_type: benefit_type,
        contested_issue_description: "PTSD denied"
      )
    end

    let(:request_issues) { [request_issue] }

    before do
      decision_review.reload.create_issues!(request_issues)
      decision_review.establish!
      decision_review.veteran.update!(participant_id: "locked_rating")
    end

    it "returns an error message about the locked rating" do
      visit "#{url_path}/#{decision_review.uuid}/edit"

      expect(page).to have_content("One or more ratings may be locked on this Claim.")
    end
  end

  context "when there is a non-rating end product" do
    let!(:nonrating_request_issue) do
      RequestIssue.create!(
        decision_review: supplemental_claim,
        nonrating_issue_category: "Military Retired Pay",
        nonrating_issue_description: "nonrating description",
        benefit_type: benefit_type,
        decision_date: 1.month.ago,
        contested_decision_issue: contested_decision_issue
      )
    end

    before do
      supplemental_claim.create_issues!([nonrating_request_issue])
      supplemental_claim.establish!
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
        date: profile_date.mdY
      )

      safe_click("#button-submit-update")

      expect(page).to have_content("The review originally had 1 issue but now has 2.")
      safe_click ".confirm"

      expect(page).to have_current_path(
        "/supplemental_claims/#{nonrating_ep_claim_id}/edit/confirmation"
      )
    end

    context "when it is created due to a DTA error" do
      let(:decision_review_remanded) { create(:higher_level_review) }
      let(:contested_decision_issue) { create(:decision_issue, :nonrating, disposition: "remanded") }

      it "only allows users to edit contention text" do
        nonrating_dta_claim_id = EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040HDENR"
        ).reference_id

        visit "supplemental_claims/#{nonrating_dta_claim_id}/edit"

        expect(page).to have_content("Edit Issues")

        # User cannot add issues
        expect(page).to_not have_css("#button-add-issue")

        # User cannot remove issues
        expect(page).to_not have_css(".remove-issue")

        # User can edit contention text
        edit_contention_text("Military Retired Pay", "New description")
        expect(page).to have_content("New description")
        click_edit_submit

        expect(RequestIssue.where(edited_description: "New description")).to_not be_nil
      end
    end
  end

  context "when there is a rating end product" do
    before { FeatureToggle.enable!(:contestable_rating_decisions) }
    after { FeatureToggle.disable!(:contestable_rating_decisions) }

    let(:request_issue) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_date: rating.promulgation_date,
        decision_review: supplemental_claim,
        benefit_type: benefit_type,
        contested_issue_description: "PTSD denied",
        contested_decision_issue: contested_decision_issue
      )
    end

    let(:request_issues) { [request_issue] }

    before do
      supplemental_claim.create_issues!(request_issues)
      supplemental_claim.establish!
    end

    context "when it is created due to a DTA error" do
      let(:decision_review_remanded) { create(:higher_level_review) }
      let(:contested_decision_issue) { create(:decision_issue, disposition: "remanded") }

      it "only allows users to edit contention text" do
        rating_dta_claim_id = EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040HDER"
        ).reference_id

        visit "supplemental_claims/#{rating_dta_claim_id}/edit"

        expect(page).to have_content("Edit Issues")

        # User cannot add issues
        expect(page).to_not have_css("#button-add-issue")

        # User cannot remove issues
        expect(page).to_not have_css(".remove-issue")

        # User can edit contention text
        edit_contention_text("PTSD denied", "New description")
        expect(page).to have_content("New description")
        click_edit_submit

        expect(RequestIssue.where(edited_description: "New description")).to_not be_nil
      end
    end

    it "shows request issues and allows adding/removing issues" do
      visit "supplemental_claims/#{rating_ep_claim_id}/edit"

      # Check that request issues appear correctly as added issues
      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

      expect(page).to have_content("Edit Issues")
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
      click_remove_intake_issue_dropdown("PTSD denied")

      # expect a pop up
      expect(page.has_no_content?("PTSD denied")).to eq(true)

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
        date: profile_date.mdY
      )
      expect(page).to have_content("3 issues")

      # add unidentified issue
      click_intake_add_issue
      add_intake_unidentified_issue("This is an unidentified issue")
      expect(page).to have_content("4 issues")
      expect(page).to have_content("This is an unidentified issue")

      # add rating decision
      click_intake_add_issue
      add_intake_rating_issue(old_rating_decision_text)
      expect(page).to have_content("5 issues")
      expect(page).to have_content(old_rating_decision_text)
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
               decision_review: another_higher_level_review)
      end

      before do
        another_higher_level_review.create_issues!([active_nonrating_request_issue])
      end

      scenario "shows ineligibility message and saves conflicting request issue id" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        click_intake_add_issue
        click_intake_no_matching_issues

        fill_in "Issue category", with: active_nonrating_request_issue.nonrating_issue_category
        find("#issue-category").send_keys :enter
        expect(page).to have_content("Does issue 2 match any of the issues actively being reviewed?")
        expect(page).to have_content("#{active_nonrating_request_issue.nonrating_issue_category}: " \
                                     "#{active_nonrating_request_issue.description}")
        add_active_intake_nonrating_issue(active_nonrating_request_issue.nonrating_issue_category)
        expect(page).to have_content("#{active_nonrating_request_issue.nonrating_issue_category} -" \
                                     " #{active_nonrating_request_issue.description}" \
                                     " is ineligible because it's already under review as a Higher-Level Review")

        safe_click("#button-submit-update")
        safe_click ".confirm"
        expect(page).to have_current_path(
          "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
        )

        expect(
          RequestIssue.find_by(
            decision_review: supplemental_claim,
            nonrating_issue_category: active_nonrating_request_issue.nonrating_issue_category,
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
          decision_review: supplemental_claim,
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
          decision_review: already_active_hlr,
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

      it "does not remove & read unedited issues" do
        verify_request_issue_contending_decision_issue_not_readded(
          "supplemental_claims/#{rating_ep_claim_id}/edit",
          supplemental_claim,
          DecisionIssue.where(id: [decision_request_issue.contested_decision_issue_id,
                                   nonrating_decision_request_issue.contested_decision_issue_id])
        )
      end
    end

    it "enables save button only when dirty" do
      visit "supplemental_claims/#{rating_ep_claim_id}/edit"

      expect(page).to have_button("Save", disabled: true)

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      click_remove_intake_issue_dropdown("Left knee granted")

      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_button("Save", disabled: true)
    end

    scenario "shows error message if an update is in progress" do
      RequestIssuesUpdate.create!(
        review: supplemental_claim,
        user: current_user,
        before_request_issue_ids: [request_issue.id],
        after_request_issue_ids: [request_issue.id],
        attempted_at: Time.zone.now,
        last_submitted_at: Time.zone.now,
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
      click_remove_intake_issue_dropdown("PTSD denied")
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")

      expect(page).to have_current_path(
        "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
      )

      # reload to verify that the new issues populate the form
      click_on "correct the issues"
      supplemental_claim.reload
      expect(page).to have_current_path("/supplemental_claims/#{supplemental_claim.uuid}/edit")
      expect(page).to have_content("Left knee granted")
      expect(page).to_not have_content("PTSD denied")

      # assert server has updated data
      new_request_issue = supplemental_claim.request_issues.active.first
      expect(new_request_issue.description).to eq("Left knee granted")
      expect(request_issue.reload.decision_review).to_not be_nil
      expect(request_issue.contention_removed_at).to eq(Time.zone.now)
      expect(request_issue.closed_at).to eq(Time.zone.now)
      expect(request_issue).to be_closed
      expect(request_issue).to be_removed
      expect(new_request_issue.rating_issue_associated_at).to eq(Time.zone.now)

      # expect contentions to reflect issue update
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: veteran.file_number,
        claim_id: rating_ep_claim_id,
        contentions: [{ description: "Left knee granted",
                        contention_type: Constants.CONTENTION_TYPES.supplemental_claim }],
        user: current_user,
        claim_date: supplemental_claim.receipt_date.to_date
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

    context "when EPs have cleared very recently" do
      before do
        ep = supplemental_claim.reload.end_product_establishments.first.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(veteran.file_number, ep.claim_id, "CLR")
      end

      it "syncs on initial GET" do
        expect(supplemental_claim.end_product_establishments.first.last_synced_at).to be_nil

        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"
        expect(page).to have_current_path("/supplemental_claims/#{rating_ep_claim_id}/edit/cleared_eps")
        expect(page).to have_content("Issues Not Editable")
      end
    end

    context "when a user can withdraw issues" do
      before do
        CaseReview.singleton.add_user(current_user)
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original
      end

      scenario "remove an issue with dropdown" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"
        expect(page).to have_content("PTSD denied")
        click_remove_intake_issue_dropdown("PTSD denied")
        expect(page).to_not have_content("PTSD denied")
      end

      let(:withdraw_date) { 1.day.ago.to_date.mdY }

      scenario "withdraw a review" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"

        expect(page).to_not have_content("Withdrawn issues")
        expect(page).to_not have_content("Please include the date the withdrawal was requested")
        expect(page).to have_content("Requested issues\n1. PTSD denied")

        click_withdraw_intake_issue_dropdown("PTSD denied")

        expect(page).to_not have_content("Requested issues\n1. PTSD denied")
        expect(page).to have_content("1. PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending")
        expect(page).to have_content("Please include the date the withdrawal was requested")

        fill_in "withdraw-date", with: withdraw_date

        expect(page).to have_content("This review will be withdrawn.")
        expect(page).to have_button("Withdraw", disabled: false)

        click_edit_submit
        expect(page).to have_current_path(
          "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Review Withdrawn")
        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.supplemental_claim} has been withdrawn.")
        expect(page).to have_content("Withdrawn\nPTSD denied")

        withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first

        expect(withdrawn_issue).to_not be_nil
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)
        expect(withdrawn_issue.decision_review.end_product_establishments.first.synced_status).to eq("CAN")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once
      end

      scenario "show withdrawn issue when edit page is reloaded" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"

        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_button("Save", disabled: false)

        safe_click("#button-submit-update")
        expect(page).to have_content("Number of issues has changed")

        safe_click ".confirm"
        expect(page).to have_current_path(
          "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
        )
        # reload to verify that the new issues populate the form
        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"
        expect(page).to have_content("Left knee granted")

        click_withdraw_intake_issue_dropdown("PTSD denied")

        expect(page).to_not have_content("Requested issues\n1. PTSD denied")
        expect(page).to have_content(
          /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
        )
        expect(page).to have_content("Please include the date the withdrawal was requested")

        fill_in "withdraw-date", with: withdraw_date

        safe_click("#button-submit-update")
        expect(page).to have_current_path(
          "/supplemental_claims/#{rating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Claim Issues Saved")

        withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first
        expect(withdrawn_issue).to_not be_nil
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)

        sleep 1

        # reload to verify that the new issues populate the form
        visit "supplemental_claims/#{rating_ep_claim_id}/edit/"

        expect(find("div", class: "issue-container", match: :first)).to have_content("Left knee granted")
        expect(find("div", class: "withdrawn-issue")).to have_content(
          "PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawn on"
        )
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)
      end
    end
  end

  describe "Establishment credits" do
    let(:url_path) { "supplemental_claims" }
    let(:decision_review) { supplemental_claim }
    let(:request_issues) { [request_issue] }
    let(:request_issue) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_review: decision_review,
        benefit_type: benefit_type,
        contested_issue_description: "PTSD denied"
      )
    end

    context "when the EP has not yet been established" do
      before do
        decision_review.reload.create_issues!(request_issues)
      end

      it "disallows editing" do
        visit "#{url_path}/#{decision_review.uuid}/edit"

        expect(page).to have_content("Review not editable")
        expect(page).to have_content("Review not yet established in VBMS. Check the job page for details.")
        expect(page).to have_link("the job page")

        click_link "the job page"

        expect(current_path).to eq decision_review.async_job_url
      end
    end

    context "when the EP has been established" do
      before do
        decision_review.reload.create_issues!(request_issues)
        decision_review.establish!
      end

      it "shows when and by whom the Intake was performed" do
        visit "#{url_path}/#{decision_review.uuid}/edit"

        expect(page).to have_content(
          "Established #{decision_review.establishment_processed_at.friendly_full_format} by #{intake.user.css_id}"
        )
      end
    end
  end

  context "when remove decision reviews is enabled for supplemental_claim" do
    before do
      non_comp_org.add_user(current_user)

      # skip the sync call since all edit requests require resyncing
      # currently, we're not mocking out vbms and bgs
      allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    end

    let(:today) { Time.zone.now }
    let(:last_week) { Time.zone.now - 7.days }
    let(:supplemental_claim) do
      # reload to get uuid
      create(:supplemental_claim, :processed, veteran_file_number: veteran.file_number).reload
    end
    let!(:existing_request_issues) do
      [create(:request_issue, :nonrating, decision_review: supplemental_claim),
       create(:request_issue, :nonrating, decision_review: supplemental_claim),
       create(:request_issue, :nonrating, decision_review: supplemental_claim),
       create(:request_issue, :nonrating, decision_review: supplemental_claim)]
    end
    let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
    let!(:completed_task) do
      create(:higher_level_review_task,
             :completed,
             appeal: supplemental_claim,
             assigned_to: non_comp_org,
             closed_at: last_week)
    end

    context "when review has multiple active tasks" do
      let!(:in_progress_task) do
        create(:higher_level_review_task,
               :in_progress,
               appeal: supplemental_claim,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      end

      scenario "cancel all active tasks when all request issues are removed" do
        visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
        # remove all request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")

        click_edit_submit_and_confirm

        expect(page).to have_content("Review Removed")
        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)

        # going back to the edit page does not show any requested issues
        visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
        expect(page.has_no_content?(existing_request_issues.first.description)).to eq(true)
        expect(page.has_no_content?(existing_request_issues.second.description)).to eq(true)
      end

      scenario "no active tasks cancelled when request issues remain" do
        visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
        # only cancel 1 of the 2 request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_edit_submit_and_confirm

        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.in_progress)
      end

      context "show alert when issues are withdrawn" do
        let(:supplemental_claim) do
          # reload to get uuid
          create(:supplemental_claim,
                 :processed,
                 veteran_file_number: veteran.file_number,
                 benefit_type: "education").reload
        end

        before do
          education_org = create(:business_line, name: "Education", url: "education")
          education_org.add_user(current_user)
        end

        let(:withdraw_date) { 1.day.ago.to_date.mdY }

        scenario "show alert message when all decision reviews are withdrawn" do
          visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
          click_withdraw_intake_issue_dropdown(1)
          click_withdraw_intake_issue_dropdown(2)
          click_withdraw_intake_issue_dropdown(3)
          click_withdraw_intake_issue_dropdown(4)
          fill_in "withdraw-date", with: withdraw_date
          click_edit_submit

          expect(page).to have_current_path("/decision_reviews/education")
          expect(page).to have_content("You have successfully withdrawn a review.")
        end

        scenario "show alert message when a decision review is withdrawn" do
          visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
          click_withdraw_intake_issue_dropdown(1)
          fill_in "withdraw-date", with: withdraw_date
          click_edit_submit

          expect(page).to have_current_path("/decision_reviews/education")
          expect(page).to have_content("You have successfully withdrawn 1 issue.")
        end

        scenario "show alert message when a decision review is removed" do
          visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
          click_remove_intake_issue_dropdown("1")
          click_edit_submit_and_confirm

          expect(page).to have_current_path("/decision_reviews/education")
          expect(page).to have_content("You have successfully removed 1 issue.")
        end

        scenario "show alert message when a decision review is added, removed and withdrawn" do
          visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
          click_intake_add_issue
          expect(page.text).to match(/Does issue \d+ match any of these non-rating issue categories?/)
          add_intake_nonrating_issue(
            category: "Accrued",
            description: "Description for Accrued",
            date: 1.day.ago.to_date.mdY
          )
          click_remove_intake_issue_dropdown("Apportionment")
          click_withdraw_intake_issue_dropdown("Apportionment")
          fill_in "withdraw-date", with: withdraw_date
          click_edit_submit

          expect(page).to have_current_path("/decision_reviews/education")
          expect(page).to have_content("You have successfully added 1 issue, removed 1 issue, and withdrawn 1 issue.")
        end
      end

      context "when review has no active tasks" do
        scenario "no tasks are cancelled when all request issues are removed" do
          visit "supplemental_claims/#{supplemental_claim.uuid}/edit"
          click_remove_intake_issue_dropdown("Apportionment")

          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
          expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end
    end
  end
end
