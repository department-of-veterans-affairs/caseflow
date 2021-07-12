# frozen_string_literal: true

feature "Higher Level Review Edit issues", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)
    FeatureToggle.enable!(:use_ama_activation_date)
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
  let(:promulgation_date) { receipt_date - 1 }
  let(:profile_date) { (receipt_date - 2.days).to_datetime }

  let!(:rating) { generate_rating_with_defined_contention(veteran, promulgation_date, profile_date) }
  let!(:rating_before_ama) { generate_pre_ama_rating(veteran) }
  let!(:rating_before_ama_from_ramp) { generate_rating_before_ama_from_ramp(veteran) }
  let!(:ratings_with_legacy_issues) do
    generate_rating_with_legacy_issues(veteran, receipt_date - 4.days, receipt_date - 4.days)
  end
  let(:request_issue_decision_mdY) { request_issue.decision_or_promulgation_date.mdY }

  let(:legacy_opt_in_approved) { false }

  let(:benefit_type) { "compensation" }

  let!(:higher_level_review) do
    create(
      :higher_level_review,
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      informal_conference: false,
      same_office: false,
      benefit_type: benefit_type,
      veteran_is_not_claimant: true,
      legacy_opt_in_approved: legacy_opt_in_approved
    )
  end

  let!(:another_higher_level_review) do
    create(
      :higher_level_review,
      :processed,
      intake: create(:intake),
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      informal_conference: false,
      same_office: false,
      benefit_type: "compensation"
    )
  end

  # create associated intake
  let!(:intake) do
    create(
      :intake,
      user: current_user,
      detail: higher_level_review,
      veteran_file_number: veteran.file_number,
      started_at: Time.zone.now,
      completed_at: Time.zone.now,
      completion_status: "success",
      type: "HigherLevelReviewIntake"
    )
  end

  let(:participant_id) { "5382910292" }

  let(:request_issue) do
    create(
      :request_issue,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: rating.profile_date,
      decision_review: higher_level_review,
      benefit_type: benefit_type,
      contested_issue_description: "PTSD denied",
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id
    )
  end
  let(:vacols_id) { nil }
  let(:vacols_sequence_id) { nil }

  before do
    higher_level_review.create_claimant!(participant_id: participant_id, payee_code: "10", type: "DependentClaimant")

    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
      first_name: "BOB",
      last_name: "VANCE",
      ptcpnt_id: participant_id,
      relationship_type: "Spouse"
    )
  end

  context "when contentions disappear from VBMS between creation and edit" do
    before do
      higher_level_review.create_issues!([request_issue])
      higher_level_review.establish!
      higher_level_review.reload
      request_issue.reload
      Fakes::VBMSService.remove_contention!(request_issue.contention)
    end

    it "automatically removes issues" do
      visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

      expect(page).to_not have_content("PTSD denied")
      expect(request_issue.reload).to be_closed
    end
  end

  context "When an opted-in issue no longer exists in VACOLS" do
    let(:vacols_id) { "vacols1" }
    let(:vacols_sequence_id) { "2" }

    before do
      setup_active_eligible_legacy_appeal(veteran.file_number)
      higher_level_review.create_issues!([request_issue])
      higher_level_review.establish!
      higher_level_review.reload
      request_issue.reload
      IssueRepository.delete_vacols_issue!(vacols_id: "vacols1", vacols_sequence_id: 2)
    end

    it "edit page loads and does not show VACOLS issue" do
      visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

      expect(page).to have_content("PTSD denied")
      expect(page).to_not have_content(COPY::VACOLS_OPTIN_ISSUE_CLOSED_EDIT)

      # Add another issue in order to also check the confirmation page
      click_intake_add_issue
      add_intake_rating_issue("Back pain")
      select_intake_no_match
      click_edit_submit_and_confirm

      expect(page).to have_current_path(
        "/higher_level_reviews/#{higher_level_review.uuid}/edit/confirmation"
      )
      expect(page).to have_content("A Higher-Level Review Rating EP is being updated")
    end
  end

  context "when a contention has an exam scheduled" do
    let(:request_issue) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_review: higher_level_review,
        benefit_type: benefit_type,
        contested_issue_description: "PTSD denied"
      )
    end

    before do
      FeatureToggle.enable!(:detect_contention_exam)
      higher_level_review.create_issues!([request_issue])
      higher_level_review.establish!
      higher_level_review.reload
      request_issue.reload
      request_issue.contention.orig_source_type_code = "EXAM"
      Fakes::BGSService.end_product_store.update_contention(request_issue.contention)
    end
    after { FeatureToggle.disable!(:detect_contention_exam) }

    it "prevents removal of request issue" do
      visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

      expect(page).to_not have_content("Remove issue")
      expect(page).to_not have_content("Withdraw issue")
      expect(page).to have_content(COPY::INTAKE_CONTENTION_HAS_EXAM_REQUESTED)
    end
  end

  context "when there are ineligible issues" do
    ineligible = Constants.INELIGIBLE_REQUEST_ISSUES

    let!(:eligible_request_issue) do
      create(
        :request_issue,
        decision_review: higher_level_review,
        nonrating_issue_category: "Military Retired Pay",
        nonrating_issue_description: "eligible nonrating description",
        ineligible_reason: nil,
        benefit_type: "compensation",
        decision_date: Time.zone.today
      )
    end

    let!(:untimely_request_issue) do
      create(
        :request_issue,
        decision_review: higher_level_review,
        decision_date: 2.years.ago,
        nonrating_issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "untimely nonrating description",
        benefit_type: "compensation",
        ineligible_reason: :untimely
      )
    end

    let!(:ri_in_review) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_date: rating.promulgation_date,
        decision_review: another_higher_level_review,
        contested_issue_description: "PTSD denied",
        benefit_type: "compensation",
        ineligible_reason: nil,
        contention_removed_at: nil
      )
    end

    let!(:ri_with_active_previous_review) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_date: rating.promulgation_date,
        decision_review: higher_level_review,
        contested_issue_description: "PTSD denied",
        ineligible_reason: :duplicate_of_rating_issue_in_active_review,
        benefit_type: "compensation",
        ineligible_due_to: ri_in_review
      )
    end

    let!(:ri_previous_hlr) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "abc123",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_date: rating.promulgation_date,
        decision_review: another_higher_level_review,
        benefit_type: "compensation",
        contested_issue_description: "Left knee granted",
        contention_reference_id: 55,
        closed_at: 2.months.ago
      )
    end

    let!(:ri_with_previous_hlr) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "abc123",
        contested_rating_issue_profile_date: rating.profile_date,
        decision_date: rating.promulgation_date,
        decision_review: higher_level_review,
        contested_issue_description: "Left knee granted",
        benefit_type: "compensation",
        ineligible_reason: :higher_level_review_to_higher_level_review,
        ineligible_due_to: ri_previous_hlr
      )
    end

    let!(:ri_before_ama) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "before_ama_ref_id",
        contested_rating_issue_profile_date: rating_before_ama.profile_date,
        decision_date: rating_before_ama.promulgation_date,
        decision_review: higher_level_review,
        benefit_type: "compensation",
        contested_issue_description: "Non-RAMP Issue before AMA Activation",
        ineligible_reason: :before_ama,
        untimely_exemption: true
      )
    end

    let!(:eligible_ri_before_ama) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "ramp_ref_id",
        contested_rating_issue_profile_date: rating_before_ama_from_ramp.profile_date,
        decision_date: rating_before_ama_from_ramp.promulgation_date,
        decision_review: higher_level_review,
        benefit_type: "compensation",
        contested_issue_description: "Issue before AMA Activation from RAMP",
        ramp_claim_id: "ramp_claim_id",
        untimely_exemption: true
      )
    end

    let!(:ri_legacy_issue_not_withdrawn) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "has_legacy_issue",
        contested_rating_issue_profile_date: rating_before_ama.profile_date,
        decision_date: rating_before_ama.promulgation_date,
        decision_review: higher_level_review,
        contested_issue_description: "Issue with legacy issue not withdrawn",
        vacols_id: "vacols1",
        benefit_type: "compensation",
        vacols_sequence_id: "1",
        ineligible_reason: :legacy_issue_not_withdrawn
      )
    end

    let!(:ri_legacy_issue_ineligible) do
      create(
        :request_issue,
        contested_rating_issue_reference_id: "has_ineligible_legacy_appeal",
        contested_rating_issue_profile_date: rating_before_ama.profile_date,
        decision_date: rating_before_ama.promulgation_date,
        decision_review: higher_level_review,
        contested_issue_description: "Issue connected to ineligible legacy appeal",
        vacols_id: "vacols2",
        benefit_type: "compensation",
        vacols_sequence_id: "2",
        ineligible_reason: :legacy_appeal_not_eligible
      )
    end

    let(:ep_claim_id) do
      EndProductEstablishment.find_by(
        source: higher_level_review,
        code: "030HLRNR"
      ).reference_id
    end

    let!(:starting_request_issues) do
      [
        eligible_request_issue,
        untimely_request_issue,
        ri_with_active_previous_review,
        ri_with_previous_hlr,
        ri_before_ama,
        eligible_ri_before_ama,
        ri_legacy_issue_not_withdrawn,
        ri_legacy_issue_ineligible
      ]
    end

    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
      another_higher_level_review.create_issues!([ri_in_review])
      higher_level_review.create_issues!(starting_request_issues)
      higher_level_review.establish!
    end

    context "VACOLS issue from before AMA opted in" do
      let!(:ri_legacy_issue_eligible) do
        create(
          :request_issue,
          contested_rating_issue_reference_id: "before_ama_ref_id",
          contested_rating_issue_profile_date: rating_before_ama.profile_date,
          decision_date: rating_before_ama.promulgation_date,
          decision_review: higher_level_review,
          contested_issue_description: "Non-RAMP Issue before AMA Activation legacy",
          vacols_id: "vacols1",
          benefit_type: "compensation",
          vacols_sequence_id: "2"
        )
      end
      let!(:starting_request_issues) do
        [
          eligible_request_issue,
          untimely_request_issue,
          ri_with_active_previous_review,
          ri_with_previous_hlr,
          ri_before_ama,
          eligible_ri_before_ama,
          ri_legacy_issue_not_withdrawn,
          ri_legacy_issue_ineligible,
          ri_legacy_issue_eligible
        ]
      end
      let(:legacy_opt_in_approved) { true }

      it "shows the Higher-Level Review Edit page with ineligibility messages" do
        visit "higher_level_reviews/#{ep_claim_id}/edit"

        expect(page).to have_content(
          "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
        )
        expect(page).to have_content(
          "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
        )
        expect(page).to have_content(
          "#{COPY::VACOLS_OPTIN_ISSUE_CLOSED_EDIT}:\nService connection, limitation of thigh motion (extension)"
        )

        expect(page).to have_content(
          "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
        )
        expect(page).to have_content("#{eligible_request_issue.contention_text}\nDecision date: #{Time.zone.today.mdY}")
        expect(page).to have_content(
          "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
        )
        expect(page).to have_content(
          "#{eligible_ri_before_ama.contention_text}\nDecision date:"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_ineligible.contention_text} #{ineligible.legacy_appeal_not_eligible}"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_eligible.contention_text}\nDecision date:"
        )
      end
    end

    it "re-applies eligibility check on remove/re-add of ineligible issue" do
      visit "higher_level_reviews/#{ep_claim_id}/edit"

      number_of_issues = 8

      expect(page).to have_content("#{number_of_issues} issues")

      # remove and re-add each ineligible issue. when re-added, it should always be last issue.
      # excludes ineligible legacy opt in issue because it requires the HLR to have that option selected

      # 1
      ri_legacy_issue_not_withdrawn_num = find_intake_issue_number_by_text(
        ri_legacy_issue_not_withdrawn.contention_text
      )
      expect_ineligible_issue(ri_legacy_issue_not_withdrawn_num)
      click_remove_intake_issue_dropdown(ri_legacy_issue_not_withdrawn.contention_text)

      expect(page).to_not have_content(
        "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_legacy_issue_not_withdrawn.contention_text)
      add_intake_rating_issue("ankylosis of hip")

      expect_ineligible_issue(number_of_issues)

      expect(page).to have_content(
        "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
      )

      # 4
      ri_with_previous_hlr_issue_num = find_intake_issue_number_by_text(ri_with_previous_hlr.contention_text)
      expect_ineligible_issue(ri_with_previous_hlr_issue_num)
      click_remove_intake_issue_dropdown(ri_with_previous_hlr.contention_text)
      expect(page).to_not have_content(
        "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_with_previous_hlr.contention_text)
      select_intake_no_match

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
      )

      # 5
      ri_in_review_issue_num = find_intake_issue_number_by_text(ri_in_review.contention_text)
      expect_ineligible_issue(ri_in_review_issue_num)
      click_remove_intake_issue_dropdown(ri_in_review.contention_text)

      expect(page).to_not have_content(
        "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_in_review.contention_text)
      select_intake_no_match

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
      )

      # 6
      untimely_request_issue_num = find_intake_issue_number_by_text(untimely_request_issue.contention_text)
      expect_ineligible_issue(untimely_request_issue_num)
      click_remove_intake_issue_dropdown(untimely_request_issue.contention_text)

      expect(page).to_not have_content(
        "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
      )

      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: untimely_request_issue.contention_text,
        date: "01/01/2016",
        legacy_issues: true
      )
      select_intake_no_match
      add_untimely_exemption_response("No")

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
      )

      # 7
      ri_before_ama_num = find_intake_issue_number_by_text(ri_before_ama.contention_text)
      expect_ineligible_issue(ri_before_ama_num)
      click_remove_intake_issue_dropdown(ri_before_ama.contention_text)

      expect(page).to_not have_content(
        "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_before_ama.contention_text)
      select_intake_no_match
      add_untimely_exemption_response("Yes")
      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
      )
    end
  end

  context "Nonrating issue with untimely date and VACOLS opt-in" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
      higher_level_review.reload.establish!
    end

    let(:legacy_opt_in_approved) { true }

    it "does not apply untimely check to legacy opt-in" do
      visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Dependent Child - Biological",
        description: "test",
        date: "01/01/2010",
        legacy_issues: true
      )
      add_intake_rating_issue("ankylosis of hip")

      expect(page).to have_content(COPY::VACOLS_OPTIN_ISSUE_NEW)

      click_edit_submit_and_confirm

      expect(page).to have_current_path("/higher_level_reviews/#{higher_level_review.uuid}/edit/confirmation")

      click_on "correct the issues"

      expect(page).to have_current_path("/higher_level_reviews/#{higher_level_review.uuid}/edit")
      expect(page).to have_content(COPY::VACOLS_OPTIN_ISSUE_CLOSED_EDIT)
    end
  end

  context "when there is a nonrating end product" do
    let!(:nonrating_request_issue) do
      RequestIssue.create!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Military Retired Pay",
        nonrating_issue_description: "nonrating description",
        benefit_type: "compensation",
        decision_date: 1.month.ago
      )
    end

    let(:nonrating_ep_claim_id) do
      EndProductEstablishment.find_by(
        source: higher_level_review,
        code: "030HLRNR"
      ).reference_id
    end

    before do
      higher_level_review.create_issues!([nonrating_request_issue])
      higher_level_review.establish!
    end

    it "shows the Higher-Level Review Edit page with a nonrating claim id" do
      visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"

      expect(page).to have_content("Military Retired Pay")

      click_intake_add_issue

      rating_date = promulgation_date.mdY
      expect(page).to have_content("Past decisions from #{rating_date}")

      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "A description!",
        date: profile_date.mdY
      )

      click_intake_add_issue
      click_intake_no_matching_issues

      add_intake_nonrating_issue(
        category: "Drill Pay Adjustments",
        description: "A nonrating issue before AMA",
        date: pre_ama_start_date.to_date.mdY
      )
      add_untimely_exemption_response("Yes")

      safe_click("#button-submit-update")

      expect(page).to have_content("The review originally had 1 issue but now has 3.")
      expect(page).to have_content(
        "A nonrating issue before AMA #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
      )
      safe_click ".confirm"

      expect(page).to have_current_path(
        "/higher_level_reviews/#{nonrating_ep_claim_id}/edit/confirmation"
      )
    end

    context "when veteran has active nonrating request issues" do
      let!(:active_nonrating_request_issue) do
        create(:request_issue,
               :nonrating,
               decision_review: another_higher_level_review,
               nonrating_issue_category: "Accrued Benefits")
      end

      before do
        another_higher_level_review.create_issues!([active_nonrating_request_issue])
      end

      scenario "shows ineligibility message and saves conflicting request issue id" do
        visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"
        click_intake_add_issue
        click_intake_no_matching_issues

        click_dropdown(text: active_nonrating_request_issue.nonrating_issue_category)
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
          "/higher_level_reviews/#{nonrating_ep_claim_id}/edit/confirmation"
        )

        expect(
          RequestIssue.find_by(
            decision_review: higher_level_review,
            nonrating_issue_category: active_nonrating_request_issue.nonrating_issue_category,
            ineligible_due_to: active_nonrating_request_issue.id,
            closed_status: :ineligible,
            ineligible_reason: "duplicate_of_nonrating_issue_in_active_review",
            nonrating_issue_description: active_nonrating_request_issue.description,
            decision_date: active_nonrating_request_issue.decision_date
          )
        ).to_not be_nil
      end
    end

    context "nonrating request issue was added and then removed" do
      let!(:active_nonrating_request_issue) do
        create(
          :request_issue,
          :nonrating,
          decision_review: higher_level_review
        )
      end

      before do
        higher_level_review.create_issues!([active_nonrating_request_issue])
        active_nonrating_request_issue.remove!
        higher_level_review.reload
      end

      it "does not appear as a potential match on edit" do
        visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"
        click_intake_add_issue
        click_intake_no_matching_issues
        click_dropdown(text: active_nonrating_request_issue.nonrating_issue_category)

        expect(page).to have_content("Does issue 2 match any of these non-rating issue categories?")
        expect(page).to_not have_content("Does issue match any of the issues actively being reviewed?")
        expect(page).to_not have_content("nonrating issue description")
      end
    end
  end

  context "Veteran has no ratings" do
    let!(:higher_level_review) do
      HigherLevelReview.create!(
        veteran_file_number: veteran_no_ratings.file_number,
        receipt_date: receipt_date,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation"
      )
    end
    let(:veteran_no_ratings) do
      Generators::Veteran.build(
        file_number: "55555555",
        first_name: "Nora",
        last_name: "Attings",
        participant_id: "44444444"
      )
    end
    let(:request_issue) do
      create(
        :request_issue,
        :nonrating,
        nonrating_issue_description: "nonrating issue desc",
        decision_review: higher_level_review
      )
    end
    let(:rating_ep_claim_id) do
      higher_level_review.end_product_establishments.first.reference_id
    end

    before do
      higher_level_review.create_issues!([request_issue])
      higher_level_review.establish!
    end

    scenario "the Add Issue modal skips directly to Nonrating Issue modal" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

      expect(page).to have_content("Edit Issues")

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: profile_date.mdY
      )

      expect(page).to have_content("2 issues")
    end
  end

  context "when the HLR has a non-compensation benefit type" do
    let(:benefit_type) { "education" }
    let(:request_issues) { [request_issue] }
    let!(:request_issue) do
      create(
        :request_issue,
        decision_review: higher_level_review,
        nonrating_issue_category: "Accrued",
        decision_date: 1.month.ago,
        nonrating_issue_description: "test description"
      )
    end

    before do
      higher_level_review.create_issues!(request_issues)
      higher_level_review.establish!
      higher_level_review.reload
    end

    it "does not mention VBMS when removing an issue" do
      visit "/higher_level_reviews/#{higher_level_review.uuid}/edit"
      expect(page).to have_content(request_issue.nonrating_issue_description)
      click_remove_intake_issue_dropdown(request_issue.nonrating_issue_description)
    end
  end

  context "when the rating issue is locked" do
    let(:url_path) { "higher_level_reviews" }
    let(:decision_review) { higher_level_review }
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

  describe "Establishment credits" do
    let(:url_path) { "higher_level_reviews" }
    let(:decision_review) { higher_level_review }
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

  context "when there is a rating end product" do
    let!(:request_issue) do
      create(
        :request_issue,
        decision_review: higher_level_review,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        contested_issue_description: "PTSD denied"
      )
    end

    let(:request_issues) { [request_issue] }

    let(:rating_ep_claim_id) do
      EndProductEstablishment.find_by(
        source: higher_level_review,
        code: "030HLRR"
      ).reference_id
    end

    before do
      higher_level_review.create_issues!(request_issues)
      higher_level_review.establish!
    end

    context "when request issues are read only" do
      before do
        # Associated ratings are fetched between established at and now
        # So if established_at is the same as now, it will always return the NilRatingProfileListError
        request_issue.end_product_establishment.update!(established_at: receipt_date)

        Generators::PromulgatedRating.build(
          participant_id: veteran.participant_id,
          profile_date: receipt_date + 10.days,
          promulgation_date: receipt_date + 10.days,
          issues: [
            {
              reference_id: "ref_id1", decision_text: "PTSD denied",
              contention_reference_id: request_issue.reload.contention_reference_id
            }
          ],
          associated_claims: [{ clm_id: rating_ep_claim_id, bnft_clm_tc: "030HLRR" }]
        )
      end

      it "does not allow to edit request issue" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        expect(page).to have_content(COPY::INTAKE_RATING_MAY_BE_PROCESS)
      end
    end

    context "has decision issues" do
      let(:contested_decision_issues) { setup_prior_decision_issues(veteran) }

      let(:decision_request_issue) do
        create(
          :request_issue,
          decision_review: higher_level_review,
          contested_issue_description: "currently contesting decision issue",
          decision_date: Time.zone.now - 2.days,
          contested_decision_issue_id: contested_decision_issues.first.id
        )
      end

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

      let(:request_issues) { [request_issue, decision_request_issue] }

      it "shows decision isssues and allows adding/removing issues" do
        verify_decision_issues_can_be_added_and_removed(
          "higher_level_reviews/#{rating_ep_claim_id}/edit",
          decision_request_issue,
          higher_level_review,
          contested_decision_issues
        )
      end
    end

    context "with existing request issues contesting decision issues" do
      let(:decision_request_issue) do
        setup_request_issue_with_nonrating_decision_issue(higher_level_review)
      end

      let(:nonrating_decision_request_issue) do
        setup_request_issue_with_rating_decision_issue(
          higher_level_review,
          contested_rating_issue_reference_id: "abc123"
        )
      end

      let(:request_issues) { [request_issue, decision_request_issue, nonrating_decision_request_issue] }

      it "does not remove & re-add unedited issues" do
        verify_request_issue_contending_decision_issue_not_readded(
          "higher_level_reviews/#{rating_ep_claim_id}/edit",
          higher_level_review,
          DecisionIssue.where(id: [decision_request_issue.contested_decision_issue_id,
                                   nonrating_decision_request_issue.contested_decision_issue_id])
        )
      end
    end

    context "when claimaint is shown on any benefit type" do
      let!(:higher_level_review) do
        HigherLevelReview.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: receipt_date,
          informal_conference: false,
          same_office: false,
          benefit_type: :pension,
          veteran_is_not_claimant: true,
          legacy_opt_in_approved: legacy_opt_in_approved
        )
      end

      let(:rating_ep_claim_id) do
        higher_level_review.end_product_establishments.first.reference_id
      end

      it "shows claimant for pension benefit type" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
        check_row("Benefit type", "Pension")
        check_row("Claimant", "Bob Vance, Spouse (payee code 10)")
      end
    end

    it "shows request issues and allows adding/removing issues" do
      # remember to check for removal later
      existing_contention = request_issue.reload.contention

      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      expect(page).to have_content("Edit Issues")
      check_row("Form", Constants.INTAKE_FORM_NAMES.higher_level_review)
      check_row("Benefit type", "Compensation")
      check_row("Claimant", "Bob Vance, Spouse (payee code 10)")

      # Check that request issues appear correctly as added issues
      expect(page).to_not have_content("Left knee granted")
      expect(page).to have_content("PTSD denied")

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

      # remove existing issue
      click_remove_intake_issue_dropdown(1)
      expect(page.has_no_content?("PTSD denied")).to eq(true)

      # re-add to proceed
      click_intake_add_issue
      add_intake_rating_issue("PTSD denied", "I am an issue note")
      expect(page).to have_content("PTSD denied")
      expect(page).to_not have_content("PTSD denied is ineligible")
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

      # Add untimely nonrating issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Another Description for Active Duty Adjustments",
        date: "04/25/2016"
      )
      add_untimely_exemption_response("No")
      expect(page).to have_content("4 issues")
      expect(page).to have_content("Another Description for Active Duty Adjustments")

      # add unidentified issue
      click_intake_add_issue
      add_intake_unidentified_issue("This is an unidentified issue")
      expect(page).to have_content("5 issues")
      expect(page).to have_content("This is an unidentified issue")
      expect(find_intake_issue_by_number(5)).to have_css(".issue-unidentified")

      # add issue before AMA
      click_intake_add_issue
      add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
      add_untimely_exemption_response("Yes")
      expect(page).to have_content(
        "Non-RAMP Issue before AMA Activation #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
      )
      expect_ineligible_issue(6)

      # add RAMP issue before AMA
      click_intake_add_issue
      add_intake_rating_issue("Issue before AMA Activation from RAMP")
      add_untimely_exemption_response("Yes")
      expect(page).to have_content("Issue before AMA Activation from RAMP\nDecision date:")

      safe_click("#button-submit-update")

      expect(page).to have_content("You still have an \"Unidentified\" issue")
      safe_click "#Unidentified-issue-button-id-1"

      expect(page).to have_content("The review originally had 1 issue but now has 7.")

      safe_click "#Number-of-issues-has-changed-button-id-1"

      expect(page).to have_current_path(
        "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
      )

      # assert server has updated data for nonrating and unidentified issues
      active_duty_adjustments_request_issue = RequestIssue.find_by!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Active Duty Adjustments",
        decision_date: profile_date,
        nonrating_issue_description: "Description for Active Duty Adjustments"
      )

      expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

      another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "Another Description for Active Duty Adjustments"
      )

      expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

      expect(
        RequestIssue.find_by(
          decision_review: higher_level_review,
          unidentified_issue_text: "This is an unidentified issue"
        )
      ).to_not be_nil

      expect(
        RequestIssue.find_by(
          decision_review: higher_level_review,
          ramp_claim_id: "ramp_claim_id"
        )
      ).to_not be_nil

      rating_epe = EndProductEstablishment.find_by!(
        source: higher_level_review,
        code: "030HLRR"
      )
      expect(rating_epe).to_not be_nil

      nonrating_epe = EndProductEstablishment.find_by!(
        source: higher_level_review,
        code: "030HLRNR"
      )
      expect(nonrating_epe).to_not be_nil

      # expect the remove/re-add to create a new RequestIssue for same RatingIssue
      expect(higher_level_review.reload.request_issues.active).to_not include(request_issue)

      new_version_of_request_issue = higher_level_review.request_issues.find do |ri|
        ri.description == request_issue.description
      end

      expect(new_version_of_request_issue.contested_rating_issue_reference_id).to eq(
        request_issue.contested_rating_issue_reference_id
      )

      # expect contentions to reflect issue update
      expect(existing_contention.text).to eq("PTSD denied")
      expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(existing_contention)

      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran.file_number,
        claim_id: rating_epe.reference_id,
        contentions: array_including(
          { description: RequestIssue::UNIDENTIFIED_ISSUE_MSG,
            contention_type: Constants.CONTENTION_TYPES.higher_level_review },
          { description: "Left knee granted",
            contention_type: Constants.CONTENTION_TYPES.higher_level_review },
          { description: "Issue before AMA Activation from RAMP",
            contention_type: Constants.CONTENTION_TYPES.higher_level_review },
          description: "PTSD denied",
          contention_type: Constants.CONTENTION_TYPES.higher_level_review
        ),
        user: current_user,
        claim_date: higher_level_review.receipt_date.to_date
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran.file_number,
        claim_id: nonrating_epe.reference_id,
        contentions: [{ description: "Active Duty Adjustments - Description for Active Duty Adjustments",
                        contention_type: Constants.CONTENTION_TYPES.higher_level_review }],
        user: current_user,
        claim_date: higher_level_review.receipt_date.to_date
      )
    end

    it "enables save button only when dirty" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

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
        review: higher_level_review,
        user: current_user,
        before_request_issue_ids: [request_issue.id],
        after_request_issue_ids: [request_issue.id],
        attempted_at: Time.zone.now,
        last_submitted_at: Time.zone.now,
        processed_at: nil
      )

      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
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

      contention_to_remove = request_issue.reload.contention

      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      click_remove_intake_issue_dropdown("PTSD denied")
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      click_edit_submit

      expect(page).to have_current_path(
        "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
      )

      # assert server has updated data
      new_request_issue = higher_level_review.reload.request_issues.active.first
      expect(new_request_issue.description).to eq("Left knee granted")
      expect(request_issue.reload.decision_review_id).to_not be_nil
      expect(request_issue).to be_closed
      expect(request_issue.contention_removed_at).to eq(Time.zone.now)
      expect(request_issue.closed_at).to eq(Time.zone.now)
      expect(request_issue.closed_status).to eq("removed")
      expect(request_issue).to be_removed
      expect(new_request_issue.rating_issue_associated_at).to eq(Time.zone.now)

      # expect contentions to reflect issue update
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: veteran.file_number,
        claim_id: rating_ep_claim_id,
        contentions: [{ description: "Left knee granted",
                        contention_type: Constants.CONTENTION_TYPES.higher_level_review }],
        user: current_user,
        claim_date: higher_level_review.receipt_date.to_date
      )
      expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
        claim_id: rating_ep_claim_id,
        rating_issue_contention_map: {
          new_request_issue.contested_rating_issue_reference_id => new_request_issue.contention_reference_id
        }
      )
      expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(contention_to_remove)

      # reload to verify that the new issues populate the form
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      expect(page).to have_content("Left knee granted")
      expect(page).to_not have_content("PTSD denied")
    end

    feature "cancel edits" do
      def click_cancel(visit_page)
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit#{visit_page}"
        click_on "Cancel"
        correct_path = "/higher_level_reviews/#{rating_ep_claim_id}/edit/cancel"
        expect(page).to have_current_path(correct_path)
        expect(page).to have_content("Edit Canceled")
        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
      end

      scenario "from landing page" do
        click_cancel("/")
      end
    end

    context "when EPs have cleared very recently" do
      before do
        ep = higher_level_review.reload.end_product_establishments.first.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(veteran.file_number, ep.claim_id, "CLR")
      end

      it "syncs on initial GET" do
        expect(higher_level_review.end_product_establishments.first.last_synced_at).to be_nil

        visit "higher_level_reviews/#{rating_ep_claim_id}/edit/"
        expect(page).to have_current_path("/higher_level_reviews/#{rating_ep_claim_id}/edit/cleared_eps")
        expect(page).to have_content("Issues Not Editable")
      end
    end

    context "when withdraw decision reviews is enabled" do
      scenario "remove an issue with dropdown" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        expect(page).to have_content("PTSD denied")
        click_remove_intake_issue_dropdown("PTSD denied")
        expect(page).to_not have_content("PTSD denied")
      end

      let(:withdraw_date) { 1.day.ago.to_date.mdY }

      scenario "withdraw a review" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit/"

        expect(page).to_not have_content("Withdrawn issues")
        expect(page).to_not have_content("Please include the date the withdrawal was requested")
        expect(page).to have_content(/Requested issues\s*[0-9]+\. PTSD denied/i)

        click_withdraw_intake_issue_dropdown("PTSD denied")
        expect(page).to_not have_content(/Requested issues\s*[0-9]+\. PTSD denied/i)
        expect(page).to have_content(
          /[0-9]+\. PTSD denied\s*Decision date: #{request_issue_decision_mdY}\s*Withdrawal pending/i
        )
        expect(page).to have_content("Please include the date the withdrawal was requested")

        fill_in "withdraw-date", with: withdraw_date

        expect(page).to have_content("This review will be withdrawn.")
        expect(page).to have_button("Withdraw", disabled: false)

        click_edit_submit

        expect(page).to have_current_path(
          "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Review Withdrawn")
        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.higher_level_review} has been withdrawn.")
        expect(page).to have_content("Withdrawn\nPTSD denied")

        withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first

        expect(withdrawn_issue).to_not be_nil
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)
        expect(withdrawn_issue.decision_review.end_product_establishments.first.synced_status).to eq("CAN")
        expect(Fakes::VBMSService).to have_received(:remove_contention!).once
      end

      scenario "show withdrawn issue when page is reloaded" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit/"

        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_button("Save", disabled: false)

        safe_click("#button-submit-update")
        expect(page).to have_content("Number of issues has changed")

        safe_click ".confirm"
        expect(page).to have_current_path(
          "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
        )
        # reload to verify that the new issues populate the form
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
        expect(page).to have_content("Left knee granted")

        click_withdraw_intake_issue_dropdown("PTSD denied")

        expect(page).to have_content(/Requested issues\s*[0-9]+\. Left knee granted/i)
        expect(page).to have_content(
          /Withdrawn issues\s*[0-9]+\. PTSD denied\s*Decision date: #{request_issue_decision_mdY}\s*Withdrawal pending/i
        )
        expect(page).to have_content("Please include the date the withdrawal was requested")

        fill_in "withdraw-date", with: withdraw_date

        safe_click("#button-submit-update")
        expect(page).to have_current_path(
          "/higher_level_reviews/#{rating_ep_claim_id}/edit/confirmation"
        )
        expect(page).to have_content("Claim Issues Saved")

        withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first
        expect(withdrawn_issue).to_not be_nil
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)

        sleep 1

        # reload to verify that the new issues populate the form
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

        expect(page).to have_content(
          /Withdrawn issues\s*[0-9]+\. PTSD denied\s*Decision date: #{request_issue_decision_mdY}\s*Withdrawn on/i
        )
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)
      end
    end
  end

  context "when remove decision reviews is enabled" do
    before do
      non_comp_org.add_user(current_user)

      # skip the sync call since all edit requests require resyncing
      # currently, we're not mocking out vbms and bgs
      allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    end

    let(:today) { Time.zone.now }
    let(:last_week) { Time.zone.now - 7.days }
    let(:higher_level_review) do
      # reload to get uuid
      create(:higher_level_review,
             :with_end_product_establishment,
             :processed,
             veteran_file_number: veteran.file_number,
             benefit_type: benefit_type).reload
    end
    let!(:existing_request_issues) do
      [create(:request_issue, :nonrating, decision_review: higher_level_review),
       create(:request_issue, :nonrating, decision_review: higher_level_review)]
    end
    let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
    let!(:completed_task) do
      create(:higher_level_review_task,
             :completed,
             appeal: higher_level_review,
             assigned_to: non_comp_org,
             closed_at: last_week)
    end

    context "when review has multiple active tasks" do
      let!(:in_progress_task) do
        create(:higher_level_review_task,
               :in_progress,
               appeal: higher_level_review,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      end

      scenario "cancel all active tasks when all request issues are removed" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        # remove all request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")
        click_edit_submit_and_confirm

        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
        expect(page).to have_content("Review Removed")
        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)

        # going back to the edit page does not show any requested issues
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

        expect(page.has_no_content?(existing_request_issues.first.description)).to eq(true)
        expect(page.has_no_content?(existing_request_issues.second.description)).to eq(true)
      end

      scenario "no active tasks cancelled when request issues remain" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        # only cancel 1 of the 2 request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_edit_submit_and_confirm

        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)

        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.in_progress)
      end

      scenario "remove all vbms decisions reviews" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        # remove all request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")

        click_edit_submit
        click_intake_confirm
        expect(page).to have_content("Review Removed")
        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)

        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
      end
    end

    context "when all caseflow decision reviews" do
      before do
        education_org = create(:business_line, name: "Education", url: "education")
        education_org.add_user(current_user)
      end

      let!(:benefit_type) { "education" }

      scenario "show alert message when all decision reviews are removed " do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        # remove all request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")

        click_edit_submit
        expect(page).to have_content(COPY::CORRECT_REQUEST_ISSUES_REMOVE_CASEFLOW_TITLE)
        expect(page).to have_content(COPY::CORRECT_REQUEST_ISSUES_REMOVE_CASEFLOW_TEXT)
        click_intake_confirm
        sleep 1

        expect(current_path).to eq("/decision_reviews/education")
        expect(page).to have_content("Edit Completed")
      end
    end

    context "show alert when entire review is withdrawn" do
      before do
        education_org = create(:business_line, name: "Education", url: "education")
        education_org.add_user(current_user)
      end

      let(:withdraw_date) { 1.day.ago.to_date.mdY }
      let!(:benefit_type) { "education" }

      scenario "show alert message when all decision reviews are withdrawn" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

        click_withdraw_intake_issue_dropdown("Apportionment")
        click_withdraw_intake_issue_dropdown("Apportionment")

        fill_in "withdraw-date", with: withdraw_date
        click_edit_submit

        expect(page).to have_current_path("/decision_reviews/education")
        expect(page).to have_content("You have successfully withdrawn a review.")
      end

      scenario "show alert message when a decision review is withdrawn" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        click_withdraw_intake_issue_dropdown("Apportionment")
        fill_in "withdraw-date", with: withdraw_date
        click_edit_submit

        expect(page).to have_current_path("/decision_reviews/education")
        expect(page).to have_content("You have successfully withdrawn 1 issue.")
      end

      scenario "show alert message when a decision review is removed" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        click_remove_intake_issue_dropdown("1")
        click_edit_submit_and_confirm

        expect(page).to have_current_path("/decision_reviews/education")
        expect(page).to have_content("You have successfully removed 1 issue.")
      end

      scenario "show alert message when a decision review is added, removed and withdrawn" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
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

    context "when a rating decision text is edited" do
      let!(:issue) do
        create(:request_issue, :rating, decision_review: higher_level_review, contested_issue_description: "PTSD")
      end

      scenario "edit contention text is saved" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        expect(page).to have_content("Edit contention title")

        within first(".issue-edit-text") do
          click_edit_contention_issue
        end

        expect(page).to have_field(type: "textarea", match: :first, text: "PTSD")
        fill_in(with: "")
        expect(page).to have_field(type: "textarea", match: :first, placeholder: "PTSD")
        expect(page).to have_button("Submit", disabled: true)

        fill_in(with: "Right Knee")
        expect(page).to have_button("Submit", disabled: false)
        click_button("Submit")
        expect(page).to have_content("Right Knee")

        click_button("Save")
        expect(RequestIssue.where(edited_description: "Right Knee")).to_not be_nil
        expect(page).to have_content("Edited")
        expect(page).to have_content("Right Knee")
      end

      context "when review has unidentified issues and non-ratings" do
        let!(:issue) do
          create(
            :request_issue,
            :unidentified,
            benefit_type: "compensation",
            decision_review: higher_level_review,
            contested_issue_description: "This is unidentified"
          )
        end

        scenario "do not show edit contention text on unidentified issues" do
          visit "higher_level_reviews/#{higher_level_review.uuid}/edit"

          expect(page).to have_content("This is unidentified")
          expect(page).to_not have_link("Edit contention title")
        end
      end
    end

    context "when review has no active tasks" do
      scenario "no tasks are cancelled when all request issues are removed" do
        visit "higher_level_reviews/#{higher_level_review.uuid}/edit"
        click_remove_intake_issue_dropdown("Apportionment")
        click_edit_submit_and_confirm

        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
      end
    end
  end
end
