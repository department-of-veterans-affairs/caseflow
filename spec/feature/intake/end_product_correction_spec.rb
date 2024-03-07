# frozen_string_literal: true

feature "End Product Correction (EP 930)", :postgres do
  include IntakeHelpers

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let(:receipt_date) { Time.zone.today - 20 }
  let(:promulgation_date) { receipt_date - 2.days }
  let(:profile_date) { promulgation_date.to_datetime }
  let(:ep_code) { "030HLRR" }

  let(:end_product) do
    Generators::EndProduct.build(
      veteran_file_number: veteran.file_number,
      bgs_attrs: { status_type_code: synced_status }
    )
  end
  let(:reference_id) { end_product.claim_id }
  let(:synced_status) { "CLR" }

  let(:end_product_establishment) do
    create(:end_product_establishment,
           source: claim_review,
           synced_status: synced_status,
           code: ep_code,
           reference_id: reference_id)
  end

  let!(:rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "abcdef", decision_text: "Back pain" }
      ]
    )
  end

  let!(:request_issue_to_correct) do
    create(
      :request_issue,
      decision_review: claim_review,
      contested_rating_issue_reference_id: "def456",
      decision_date: promulgation_date,
      contested_rating_issue_profile_date: profile_date,
      contested_issue_description: "PTSD denied",
      end_product_establishment: end_product_establishment
    )
  end

  let!(:claim_review) do
    create(claim_review_type.to_sym,
           :processed,
           intake: create(:intake),
           veteran_file_number: veteran.file_number,
           receipt_date: receipt_date)
  end

  feature "with cleared end product on higher level review" do
    let(:claim_review_type) { "higher_level_review" }
    let(:edit_path) { "#{claim_review_type.pluralize}/#{reference_id}/edit" }
    let(:ep_code) { "030HLRR" }

    it "edits are prevented if correct claim reviews feature is not enabled" do
      visit edit_path
      check_page_not_editable(claim_review_type)
    end

    context "when correct claim reviews feature is enabled" do
      before { enable_features }
      after { disable_features }

      context "when a user corrects an existing issue" do
        it "creates a correction issue and EP, and closes the existing issue with no decision" do
          visit edit_path
          correct_existing_request_issue(request_issue_to_correct)
        end
      end

      context "when a user adds a rating issue" do
        it "creates a correction issue and EP" do
          visit edit_path
          check_adding_rating_correction_issue
        end
      end

      context "when a user adds a nonrating issue" do
        let(:ep_code) { "030HLRNR" }

        it "creates a correction issue and EP" do
          visit edit_path
          check_adding_nonrating_correction_issue
        end

        it "cancel edit on cleared eps" do
          visit edit_path
          click_on "Cancel"

          correct_path = "/higher_level_reviews/#{reference_id}/edit/cancel"
          expect(page).to have_current_path(correct_path)
          expect(page).to have_content("Edit Canceled")
          expect(page).to have_content("correct the issues")
          click_on "correct the issues"
          expect(page).to have_content("Edit Issues")
        end

        it "creates a correction issue and shows type selected" do
          visit edit_path
          click_correct_intake_issue_dropdown(request_issue_to_correct.description)
          select_correction_type_from_modal("local_quality_error")
          click_correction_type_modal_submit
          expect(page).to have_content("This issue will be added to a 930 Local Quality Error EP for correction")
        end
      end

      context "when a user adds an unidentified issue" do
        it "creates a correction issue and EP" do
          visit edit_path
          check_adding_unidentified_correction_issue
        end
      end

      context "with future decision issues" do
        let!(:another_claim_review) do
          create(
            claim_review_type.to_sym,
            veteran_file_number: veteran.file_number,
            receipt_date: receipt_date + 2.days,
            intake: create(:intake)
          )
        end
        let!(:past_decision_issue_from_another_claim) do
          create(:decision_issue,
                 decision_review: another_claim_review,
                 rating_profile_date: receipt_date - 1.day,
                 end_product_last_action_date: receipt_date - 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "past decision issue",
                 participant_id: veteran.participant_id)
        end
        let!(:future_decision_issue_from_another_claim) do
          create(:decision_issue,
                 decision_review: another_claim_review,

                 rating_profile_date: receipt_date + 1.day,
                 end_product_last_action_date: receipt_date + 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "future decision issue from another review",
                 participant_id: veteran.participant_id)
        end

        let!(:future_decision_issue) do
          create(:decision_issue,
                 decision_review: claim_review,

                 rating_profile_date: receipt_date + 1.day,
                 end_product_last_action_date: receipt_date + 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "correction review decision issue",
                 participant_id: veteran.participant_id)
        end

        let!(:request_issue_duplicate) do
          create(
            :request_issue,
            decision_review: another_claim_review,
            contested_decision_issue_id: future_decision_issue.id
          )
        end

        it "allows adding decision issues from the same claim review" do
          visit edit_path
          click_intake_add_issue
          expect(page).to have_content("Left knee granted")
          expect(page).to have_content("past decision issue")
          expect(page).to_not have_content("future decision issue from another review")

          add_intake_rating_issue("correction review decision issue")
          select_correction_type_from_modal("control")
          click_correction_type_modal_submit

          expect(page).to have_content("correction review decision issue")
          expect(page).to_not have_content("is ineligible because it was last processed as")
          expect(page).to_not have_content("is ineligible because it's already under review")

          click_edit_submit
          click_number_of_issues_changed_confirmation
          confirm_930_modal

          correction_issue = RequestIssue.find_by(
            contested_issue_description: "correction review decision issue",
            correction_type: "control",
            ineligible_reason: nil
          )
          check_confirmation_page(correction_issue)
        end

        context "when decision issue is already corrected" do
          before { another_claim_review.establish! }

          let!(:request_issue_duplicate) do
            create(
              :request_issue,
              decision_review: claim_review,
              contested_decision_issue_id: future_decision_issue.id,
              correction_type: "control"
            )
          end

          it "allows veteran to add decision issue to another review" do
            visit "#{claim_review_type.pluralize}/#{another_claim_review.uuid}/edit"
            click_intake_add_issue
            add_intake_rating_issue("correction review decision issue")
            expect(page).to have_content("correction review decision issue")
            expect(page).to_not have_content("is ineligible because it's already under review")
            expect(page).to have_content("is ineligible because it was last processed as a Higher-Level Review")

            if claim_review_type == "supplemental_claim"
              expect(page).to_not have_content("is ineligible because it was last processed as")
              click_edit_submit
              click_number_of_issues_changed_confirmation
              expect(page).to have_content("Claim Issues Saved")
              new_issue = RequestIssue.find_by(
                contested_issue_description: "correction review decision issue",
                correction_type: nil,
                ineligible_reason: nil
              )
              expect(new_issue).to_not be_nil
            end
          end
        end
      end
    end
  end

  feature "with cleared end product on supplemental claim" do
    let(:claim_review_type) { "supplemental_claim" }
    let(:edit_path) { "#{claim_review_type.pluralize}/#{reference_id}/edit" }
    let(:ep_code) { "040SCR" }

    it "edits are prevented if correct claim reviews feature is not enabled" do
      visit edit_path
      check_page_not_editable(claim_review_type)
    end

    context "when correct claim reviews feature is enabled" do
      before { enable_features }
      after { disable_features }

      context "when a user corrects an existing issue" do
        it "creates a correction issue and EP, and closes the existing issue with no decision" do
          visit edit_path
          correct_existing_request_issue(request_issue_to_correct)
        end
      end

      context "when a user adds a rating issue" do
        it "creates a correction issue and EP" do
          visit edit_path
          check_adding_rating_correction_issue
        end
      end

      context "when a user adds a nonrating issue" do
        let(:ep_code) { "040SCNR" }

        it "creates a correction issue and EP" do
          visit edit_path
          check_adding_nonrating_correction_issue
        end
      end

      context "when a user adds an unidentified issue" do
        it "creates a correction issue and EP" do
          visit edit_path
          check_adding_unidentified_correction_issue
        end
      end

      context "with future decision issues" do
        let!(:another_claim_review) do
          create(
            claim_review_type.to_sym,
            veteran_file_number: veteran.file_number,
            receipt_date: receipt_date + 2.days,
            intake: create(:intake)
          )
        end
        let!(:past_decision_issue_from_another_claim) do
          create(:decision_issue,
                 decision_review: another_claim_review,
                 rating_profile_date: receipt_date - 1.day,
                 end_product_last_action_date: receipt_date - 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "past decision issue",
                 participant_id: veteran.participant_id)
        end
        let!(:future_decision_issue_from_another_claim) do
          create(:decision_issue,
                 decision_review: another_claim_review,

                 rating_profile_date: receipt_date + 1.day,
                 end_product_last_action_date: receipt_date + 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "future decision issue from another review",
                 participant_id: veteran.participant_id)
        end

        let!(:future_decision_issue) do
          create(:decision_issue,
                 decision_review: claim_review,

                 rating_profile_date: receipt_date + 1.day,
                 end_product_last_action_date: receipt_date + 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "correction review decision issue",
                 participant_id: veteran.participant_id)
        end

        let!(:request_issue_duplicate) do
          create(
            :request_issue,
            decision_review: another_claim_review,
            contested_decision_issue_id: future_decision_issue.id
          )
        end

        it "allows adding decision issues from the same claim review" do
          visit edit_path
          click_intake_add_issue
          expect(page).to have_content("Left knee granted")
          expect(page).to have_content("past decision issue")
          expect(page).to_not have_content("future decision issue from another review")

          add_intake_rating_issue("correction review decision issue")
          select_correction_type_from_modal("control")
          click_correction_type_modal_submit

          expect(page).to have_content("correction review decision issue")
          expect(page).to_not have_content("is ineligible because it was last processed as")
          expect(page).to_not have_content("is ineligible because it's already under review")

          click_edit_submit
          click_number_of_issues_changed_confirmation
          confirm_930_modal

          correction_issue = RequestIssue.find_by(
            contested_issue_description: "correction review decision issue",
            correction_type: "control",
            ineligible_reason: nil
          )
          check_confirmation_page(correction_issue)
        end

        context "when decision issue is already corrected" do
          before { another_claim_review.establish! }

          let!(:request_issue_duplicate) do
            create(
              :request_issue,
              decision_review: claim_review,
              contested_decision_issue_id: future_decision_issue.id,
              correction_type: "control"
            )
          end

          it "allows veteran to add decision issue to another review" do
            visit "#{claim_review_type.pluralize}/#{another_claim_review.uuid}/edit"
            click_intake_add_issue
            add_intake_rating_issue("correction review decision issue")
            expect(page).to have_content("correction review decision issue")
            expect(page).to_not have_content("is ineligible because it's already under review")
            expect(page).to_not have_content("is ineligible because it was last processed as")
            click_edit_submit
            click_number_of_issues_changed_confirmation
            expect(page).to have_content("Claim Issues Saved")
            new_issue = RequestIssue.find_by(
              contested_issue_description: "correction review decision issue",
              correction_type: nil,
              ineligible_reason: nil
            )
            expect(new_issue).to_not be_nil
          end
        end
      end
    end
  end

  feature "with a remand supplemental claim" do
    before { enable_features }
    after { disable_features }

    let(:claim_review_type) { "supplemental_claim" }
    let!(:claim_review) do
      create(claim_review_type.to_sym,
             :processed,
             intake: create(:intake),
             veteran_file_number: veteran.file_number,
             decision_review_remanded: create(:higher_level_review, veteran_file_number: veteran.file_number),
             receipt_date: receipt_date)
    end

    let(:edit_path) { "#{claim_review_type.pluralize}/#{reference_id}/edit" }
    let(:ep_code) { "040SCR" }

    context "when the end product is cleared" do
      context "when the review has no decision issues" do
        it "does not allow the user to add issues" do
          visit edit_path
          expect(page).to have_content("Edit Issues")
          expect(page).to_not have_css("#button-add-issue")
        end
      end

      context "when the review has decision issues" do
        let!(:decision_issue) do
          create(:decision_issue,
                 decision_review: claim_review,
                 rating_profile_date: receipt_date + 1.day,
                 end_product_last_action_date: receipt_date + 1.day,
                 benefit_type: claim_review.benefit_type,
                 decision_text: "decision issue",
                 participant_id: veteran.participant_id)
        end

        it "only allows user to add the review's decision issues" do
          visit edit_path
          expect(page).to have_content("Edit Issues")
          click_intake_add_issue
          expect(page).to have_content("decision issue")
          expect(page).to_not have_content("Left knee granted")

          # Do not allow adding new nonrating issues
          expect(page).to_not have_content("None of these match")
        end
      end
    end
  end
end

def check_page_not_editable(type)
  expect(page).to have_current_path("/#{type}s/#{reference_id}/edit/cleared_eps")
  expect(page).to have_content("Issues Not Editable")
  expect(page).to have_content(Constants.INTAKE_FORM_NAMES.send(type))
end

def check_correction_type_modal_button_status(enabled)
  if enabled
    expect(page).to have_css(".correction-type-submit:disabled")
  else
    expect(page).to have_css(".correction-type-submit:enabled")
  end
end

def check_correction_type_modal_elements
  expect(page).to have_selector(".intake-correction-type")
  expect(page).to have_selector("label[for=correctionType_control]")
  expect(page).to have_selector("label[for=correctionType_local_quality_error]")
  expect(page).to have_selector("label[for=correctionType_national_quality_error]")
end

def correct_existing_request_issue(request_issue_to_correct)
  click_correct_intake_issue_dropdown(request_issue_to_correct.description)
  check_correction_type_modal_elements
  check_correction_type_modal_button_status(true)
  select_correction_type_from_modal("control")
  check_correction_type_modal_button_status(false)
  click_correction_type_modal_submit
  click_edit_submit
  confirm_930_modal
  correction_issue = request_issue_to_correct.reload.correction_request_issue
  check_confirmation_page(correction_issue)
  expect(request_issue_to_correct.closed_status).to eq("no_decision")
end

def visit_edit_page(type)
  visit "#{type}/#{reference_id}/edit/"
  expect(page).to have_content("Edit Issues")
  expect(page).to have_content("Cleared, waiting for decision")
end

def check_adding_rating_correction_issue
  click_intake_add_issue
  add_intake_rating_issue("Left knee granted")

  select_correction_type_from_modal("control")
  click_correction_type_modal_submit

  click_edit_submit
  safe_click ".confirm"
  confirm_930_modal
  correction_issue = RequestIssue.find_by(contested_issue_description: "Left knee granted")
  check_confirmation_page(correction_issue)
end

def check_adding_nonrating_correction_issue
  description = "New nonrating correction issue"
  click_intake_add_issue
  click_intake_no_matching_issues
  add_intake_nonrating_issue(description: "New nonrating correction issue", date: promulgation_date.mdY)

  select_correction_type_from_modal("control")
  click_correction_type_modal_submit

  click_edit_submit
  safe_click ".confirm"
  confirm_930_modal
  correction_issue = RequestIssue.find_by(nonrating_issue_description: description)
  check_confirmation_page(correction_issue)
end

def check_adding_unidentified_correction_issue
  description = "New unidentified correction issue"
  click_intake_add_issue
  add_intake_unidentified_issue(description)

  select_correction_type_from_modal("control")
  click_correction_type_modal_submit

  click_edit_submit
  safe_click "#Unidentified-issue-button-id-1"
  safe_click ".confirm"

  confirm_930_modal
  correction_issue = RequestIssue.find_by(unidentified_issue_text: description)
  check_confirmation_page(correction_issue)
end

def confirm_930_modal
  expect(page).to have_content("You are now creating a 930 EP in VBMS")
  click_button("Yes, establish")
  expect(page).to have_content("Claim Issues Saved")
end

def check_confirmation_page(correction_issue)
  ep_description = Constants::END_PRODUCT_CODES[correction_issue.end_product_code]

  expect(page).to have_content("A #{ep_description} EP is being established:")
  expect(page).to have_content("Contention: #{correction_issue.contention_text}")
end

def enable_features
  FeatureToggle.enable!(:correct_claim_reviews)
end

def disable_features
  FeatureToggle.disable!(:correct_claim_reviews)
end
