require "rails_helper"

RSpec.feature "Edit issues" do
  before do
    FeatureToggle.enable!(:intake)
    FeatureToggle.enable!(:intakeAma)
    FeatureToggle.enable!(:intake_legacy_opt_in)

    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 26))
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
  let(:profile_date) { "2017-05-02T07:00:00.000Z" }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: receipt_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" }
      ]
    )
  end

  def check_row(label, text)
    row = find("tr", text: label)
    expect(row).to have_text(text)
  end

  context "appeals" do
    let!(:appeal) do
      create(:appeal,
             veteran_file_number: veteran.file_number,
             receipt_date: receipt_date,
             docket_type: "evidence_submission",
             legacy_opt_in_approved: false)
    end

    let!(:nonrating_request_issue) do
      create(:request_issue,
             review_request: appeal,
             issue_category: "Military Retired Pay",
             description: "nonrating description",
             contention_reference_id: "1234")
    end

    scenario "allows adding/removing issues" do
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("nonrating description")
      # remove an issue
      page.all(".remove-issue")[0].click
      safe_click ".remove-issue"
      expect(page).not_to have_content("nonrating description")

      # add an issue
      safe_click "#button-add-issue"
      find("label", text: "Left knee granted").click
      safe_click ".add-issue"

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
      click_on "Cancel edit"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
    end
  end

  context "Higher-Level Reviews" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation"
      )
    end

    let!(:another_higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation"
      )
    end

    # create associated intake
    let!(:intake) do
      Intake.create!(
        user_id: current_user.id,
        detail: higher_level_review,
        veteran_file_number: veteran.file_number,
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: "success",
        type: "HigherLevelReviewIntake"
      )
    end

    before do
      higher_level_review.create_claimants!(participant_id: "5382910292", payee_code: "10")

      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      )
    end

    context "when there are ineligible issues" do
      let!(:eligible_request_issue) do
        RequestIssue.create!(
          review_request: higher_level_review,
          issue_category: "Military Retired Pay",
          description: "non-rated description",
          contention_reference_id: "1234",
          ineligible_reason: nil,
          decision_date: Date.new(2018, 5, 1)
        )
      end

      let!(:untimely_request_issue) do
        RequestIssue.create!(
          review_request: higher_level_review,
          issue_category: "Active Duty Adjustments",
          description: "non-rated description",
          contention_reference_id: "12345",
          ineligible_reason: :untimely
        )
      end

      let!(:ri_in_review) do
        RequestIssue.create!(
          rating_issue_reference_id: "def456",
          rating_issue_profile_date: rating.profile_date,
          review_request: another_higher_level_review,
          description: "PTSD denied",
          contention_reference_id: "123",
          ineligible_reason: nil,
          removed_at: nil
        )
      end

      let!(:ri_with_active_previous_review) do
        RequestIssue.create!(
          rating_issue_reference_id: "def456",
          rating_issue_profile_date: rating.profile_date,
          review_request: higher_level_review,
          description: "PTSD denied",
          contention_reference_id: "123",
          ineligible_reason: :duplicate_of_issue_in_active_review,
          ineligible_due_to: ri_in_review
        )
      end

      let!(:ri_with_previous_hlr) do
        RequestIssue.create!(
          rating_issue_reference_id: "abc123",
          rating_issue_profile_date: rating.profile_date,
          review_request: higher_level_review,
          description: "Left knee granted",
          contention_reference_id: "123",
          ineligible_reason: :previous_higher_level_review
        )
      end

      before do
        another_higher_level_review.create_issues!([ri_in_review])
        higher_level_review.create_issues!([
                                             eligible_request_issue,
                                             untimely_request_issue,
                                             ri_with_active_previous_review,
                                             ri_with_previous_hlr
                                           ])
        higher_level_review.process_end_product_establishments!
      end

      it "shows the Higher-Level Review Edit page with ineligibility messages" do
        ep_claim_id = EndProductEstablishment.find_by(
          source: higher_level_review,
          code: "030HLRNR"
        ).reference_id
        visit "higher_level_reviews/#{ep_claim_id}/edit"

        expect(page).to have_content(
          "#{ri_with_previous_hlr.contention_text} #{Constants.INELIGIBLE_REQUEST_ISSUES.previous_higher_level_review}"
        )
        expect(page).to have_content(
          "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
        )
        expect(page).to have_content(
          "#{untimely_request_issue.contention_text} #{Constants.INELIGIBLE_REQUEST_ISSUES.untimely}"
        )
        expect(page).to have_content("#{eligible_request_issue.contention_text} Decision date:")
      end
    end

    context "when there is a non-rating end product" do
      let!(:nonrating_request_issue) do
        RequestIssue.create!(
          review_request: higher_level_review,
          issue_category: "Military Retired Pay",
          description: "nonrating description",
          contention_reference_id: "1234"
        )
      end

      before do
        higher_level_review.create_issues!([nonrating_request_issue])
        higher_level_review.process_end_product_establishments!
      end

      it "shows the Higher-Level Review Edit page with a nonrating claim id" do
        nonrating_ep_claim_id = EndProductEstablishment.find_by(
          source: higher_level_review,
          code: "030HLRNR"
        ).reference_id
        visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"

        expect(page).to have_content("Military Retired Pay")

        safe_click "#button-add-issue"
        safe_click ".no-matching-issues"
        fill_in "Issue category", with: "Active Duty Adjustments"
        find("#issue-category").send_keys :enter
        fill_in "Issue description", with: "A description!"
        fill_in "Decision date", with: "04/25/2018"
        safe_click ".add-issue"

        safe_click("#button-submit-update")

        expect(page).to have_content("The review originally had 1 issue but now has 2.")
        safe_click ".confirm"

        expect(page).to have_current_path(
          "/higher_level_reviews/#{nonrating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Edit Confirmed")
      end
    end

    context "when there is a rating end product" do
      let!(:request_issue) do
        RequestIssue.create!(
          rating_issue_reference_id: "def456",
          rating_issue_profile_date: rating.profile_date,
          review_request: higher_level_review,
          description: "PTSD denied",
          contention_reference_id: "123"
        )
      end

      let(:rating_ep_claim_id) do
        EndProductEstablishment.find_by(
          source: higher_level_review,
          code: "030HLRR"
        ).reference_id
      end

      before do
        higher_level_review.create_issues!([request_issue])
        higher_level_review.process_end_product_establishments!
      end

      it "shows request issues and allows adding/removing issues" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

        expect(page).to have_content("Add / Remove Issues")
        check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
        check_row("Benefit type", "Compensation")
        check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

        # Check that request issues appear correctly as added issues
        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        safe_click "#button-add-issue"

        expect(page).to have_content("Add issue 2")
        expect(page).to have_content("Does issue 2 match any of these issues")
        expect(page).to have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        # test canceling adding an issue by closing the modal
        safe_click ".close-modal"
        expect(page).to_not have_content("2. Left knee granted")

        # adding an issue should show the issue
        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"

        expect(page).to have_content("2. Left knee granted")
        expect(page).to_not have_content("Notes:")

        page.all(".remove-issue")[0].click
        safe_click ".remove-issue"
        expect(page).not_to have_content("PTSD denied")

        # re-add to proceed
        safe_click "#button-add-issue"
        find("label", text: "PTSD denied").click
        fill_in "Notes", with: "I am an issue note"
        safe_click ".add-issue"
        expect(page).to have_content("2. PTSD denied")
        expect(page).to have_content("I am an issue note")

        # clicking add issue again should show a disabled radio button for that same rating
        safe_click "#button-add-issue"
        expect(page).to have_content("Add issue 3")
        expect(page).to have_content("Does issue 3 match any of these issues")
        expect(page).to have_content("Left knee granted (already selected for issue 1)")
        expect(page).to have_css("input[disabled][id='rating-radio_abc123']", visible: false)

        # Add nonrating issue
        safe_click ".no-matching-issues"
        expect(page).to have_content("Does issue 3 match any of these issue categories?")
        expect(page).to have_button("Add this issue", disabled: true)
        fill_in "Issue category", with: "Active Duty Adjustments"
        find("#issue-category").send_keys :enter
        fill_in "Issue description", with: "Description for Active Duty Adjustments"
        fill_in "Decision date", with: "04/25/2018"
        expect(page).to have_button("Add this issue", disabled: false)
        safe_click ".add-issue"
        expect(page).to have_content("3 issues")

        # add unidentified issue
        safe_click "#button-add-issue"
        safe_click ".no-matching-issues"
        safe_click ".no-matching-issues"
        expect(page).to have_content("Describe the issue to mark it as needing further review.")
        fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
        safe_click ".add-issue"
        expect(page).to have_content("4 issues")
        expect(page).to have_content("This is an unidentified issue")

        safe_click("#button-submit-update")

        expect(page).to have_content("You still have an \"Unidentified\" issue")
        safe_click "#Unidentified-issue-button-id-1"

        expect(page).to have_content("The review originally had 1 issue but now has 4.")
        safe_click "#Number-of-issues-has-changed-button-id-1"

        expect(page).to have_content("Edit Confirmed")

        # assert server has updated data for nonrating and unidentified issues
        expect(RequestIssue.find_by(
                 review_request: higher_level_review,
                 issue_category: "Active Duty Adjustments",
                 decision_date: 1.month.ago,
                 description: "Description for Active Duty Adjustments"
        )).to_not be_nil

        expect(RequestIssue.find_by(
                 review_request: higher_level_review,
                 description: "This is an unidentified issue"
        )).to_not be_nil

        rating_epe = EndProductEstablishment.find_by!(
          source: higher_level_review,
          code: HigherLevelReview::END_PRODUCT_RATING_CODE
        )

        nonrating_epe = EndProductEstablishment.find_by!(
          source: higher_level_review,
          code: HigherLevelReview::END_PRODUCT_NONRATING_CODE
        )

        # expect contentions to reflect issue update
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran.file_number,
          claim_id: rating_epe.reference_id,
          contention_descriptions: [
            RequestIssue::UNIDENTIFIED_ISSUE_MSG,
            "PTSD denied",
            "Left knee granted"
          ],
          special_issues: [],
          user: current_user
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
          veteran_file_number: veteran.file_number,
          claim_id: nonrating_epe.reference_id,
          contention_descriptions: [
            "Active Duty Adjustments - Description for Active Duty Adjustments"
          ],
          special_issues: [],
          user: current_user
        )
      end

      it "enables save button only when dirty" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

        expect(page).to have_button("Save", disabled: true)

        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"

        expect(page).to have_button("Save", disabled: false)

        page.all(".remove-issue")[1].click
        safe_click ".remove-issue"
        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_button("Save", disabled: true)
      end

      it "Does not allow save if no issues are selected" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        safe_click ".remove-issue"
        # click again to get rid of pop up
        safe_click ".remove-issue"

        expect(page).to have_button("Save", disabled: true)
      end

      scenario "shows error message if an update is in progress" do
        RequestIssuesUpdate.create!(
          review: higher_level_review,
          user: current_user,
          before_request_issue_ids: [request_issue.id],
          after_request_issue_ids: [request_issue.id],
          attempted_at: Time.zone.now,
          submitted_at: Time.zone.now,
          processed_at: nil
        )

        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"
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

        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        safe_click ".remove-issue"
        # click again to get rid of pop-up
        safe_click ".remove-issue"
        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"

        expect(page).to have_button("Save", disabled: false)

        safe_click("#button-submit-update")

        expect(page).to have_current_path(
          "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
        )

        # reload to verify that the new issues populate the form
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        expect(page).to have_content("Left knee granted")
        expect(page).to_not have_content("PTSD denied")

        # assert server has updated data
        new_request_issue = higher_level_review.reload.request_issues.first
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
            new_request_issue.rating_issue_reference_id => new_request_issue.contention_reference_id
          }
        )
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once
      end

      feature "cancel edits" do
        def click_cancel(visit_page)
          visit "higher_level_reviews/#{rating_ep_claim_id}/edit#{visit_page}"
          click_on "Cancel edit"
          correct_path = "/higher_level_reviews/#{rating_ep_claim_id}/edit/cancel"
          expect(page).to have_current_path(correct_path)
          expect(page).to have_content("Edit Canceled")
          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
        end

        scenario "from landing page" do
          click_cancel("/")
        end
      end
    end
  end

  context "Supplemental claims" do
    let(:is_dta_error) { false }

    let!(:supplemental_claim) do
      SupplementalClaim.create!(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: "compensation",
        is_dta_error: is_dta_error
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
          description: "nonrating description",
          contention_reference_id: "1234"
        )
      end

      before do
        supplemental_claim.create_issues!([nonrating_request_issue])
        supplemental_claim.process_end_product_establishments!
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
      end

      it "shows the Supplemental Claim Edit page with a nonrating claim id" do
        nonrating_ep_claim_id = EndProductEstablishment.find_by(
          source: supplemental_claim,
          code: "040SCNR"
        ).reference_id
        visit "supplemental_claims/#{nonrating_ep_claim_id}/edit"

        expect(page).to have_content("Military Retired Pay")

        safe_click "#button-add-issue"
        safe_click ".no-matching-issues"
        fill_in "Issue category", with: "Active Duty Adjustments"
        find("#issue-category").send_keys :enter
        fill_in "Issue description", with: "A description!"
        fill_in "Decision date", with: "04/25/2018"
        safe_click ".add-issue"

        safe_click("#button-submit-update")

        expect(page).to have_content("The review originally had 1 issue but now has 2.")
        safe_click ".confirm"

        expect(page).to have_current_path(
          "/supplemental_claims/#{nonrating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Edit Confirmed")
      end
    end

    context "when there is a rating end product" do
      let!(:request_issue) do
        RequestIssue.create!(
          rating_issue_reference_id: "def456",
          rating_issue_profile_date: rating.profile_date,
          review_request: supplemental_claim,
          description: "PTSD denied"
        )
      end

      before do
        supplemental_claim.create_issues!([request_issue])
        supplemental_claim.process_end_product_establishments!
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

        safe_click "#button-add-issue"

        expect(page).to have_content("Add issue 2")
        expect(page).to have_content("Does issue 2 match any of these issues")
        expect(page).to have_content("Left knee granted")
        expect(page).to have_content("PTSD denied")

        # test canceling adding an issue by closing the modal
        safe_click ".close-modal"
        expect(page).to_not have_content("2. Left knee granted")

        # adding an issue should show the issue
        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"

        expect(page).to have_content("2. Left knee granted")
        expect(page).to_not have_content("Notes:")
        safe_click ".remove-issue"

        # expect a pop up
        expect(page).to have_content("Are you sure you want to remove this issue?")
        safe_click ".remove-issue"

        expect(page).not_to have_content("PTSD denied")

        # re-add to proceed
        safe_click "#button-add-issue"
        find("label", text: "PTSD denied").click
        fill_in "Notes", with: "I am an issue note"
        safe_click ".add-issue"
        expect(page).to have_content("2. PTSD denied")
        expect(page).to have_content("I am an issue note")

        # clicking add issue again should show a disabled radio button for that same rating
        safe_click "#button-add-issue"
        expect(page).to have_content("Add issue 3")
        expect(page).to have_content("Does issue 3 match any of these issues")
        expect(page).to have_content("Left knee granted (already selected for issue 1)")
        expect(page).to have_css("input[disabled][id='rating-radio_abc123']", visible: false)

        # Add nonrating issue
        safe_click ".no-matching-issues"
        expect(page).to have_content("Does issue 3 match any of these issue categories?")
        expect(page).to have_button("Add this issue", disabled: true)
        fill_in "Issue category", with: "Active Duty Adjustments"
        find("#issue-category").send_keys :enter
        fill_in "Issue description", with: "Description for Active Duty Adjustments"
        fill_in "Decision date", with: "04/25/2018"
        expect(page).to have_button("Add this issue", disabled: false)
        safe_click ".add-issue"
        expect(page).to have_content("3 issues")

        # add unidentified issue
        safe_click "#button-add-issue"
        safe_click ".no-matching-issues"
        safe_click ".no-matching-issues"
        expect(page).to have_content("Describe the issue to mark it as needing further review.")
        fill_in "Transcribe the issue as it's written on the form", with: "This is an unidentified issue"
        safe_click ".add-issue"
        expect(page).to have_content("4 issues")
        expect(page).to have_content("This is an unidentified issue")
      end

      it "enables save button only when dirty" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"

        expect(page).to have_button("Save", disabled: true)

        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"

        expect(page).to have_button("Save", disabled: false)

        page.all(".remove-issue")[1].click
        # click remove issue again to get rid of popup
        safe_click ".remove-issue"
        expect(page).to_not have_content("Left knee granted")
        expect(page).to have_button("Save", disabled: true)
      end

      it "Does not allow save if no issues are selected" do
        visit "supplemental_claims/#{rating_ep_claim_id}/edit"
        safe_click ".remove-issue"
        # click remove issue again to get rid of popup
        safe_click ".remove-issue"

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
        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"
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
        safe_click ".remove-issue"
        safe_click ".remove-issue"
        safe_click "#button-add-issue"
        find("label", text: "Left knee granted").click
        safe_click ".add-issue"

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
            new_request_issue.rating_issue_reference_id => new_request_issue.contention_reference_id
          }
        )
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once
      end

      feature "cancel edits" do
        def click_cancel(visit_page)
          visit "supplemental_claims/#{rating_ep_claim_id}/edit#{visit_page}"
          click_on "Cancel edit"
          correct_path = "/supplemental_claims/#{rating_ep_claim_id}/edit/cancel"
          expect(page).to have_current_path(correct_path)
          expect(page).to have_content("Edit Canceled")
          expect(page).to have_content(Constants.INTAKE_FORM_NAMES.supplemental_claim)
        end

        scenario "from landing page" do
          click_cancel("/")
        end
      end
    end
  end
end
