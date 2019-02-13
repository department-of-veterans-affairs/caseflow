require "support/intake_helpers"

feature "Higher Level Review Edit issues" do
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

  let(:legacy_opt_in_approved) { false }

  let(:benefit_type) { "compensation" }

  let!(:higher_level_review) do
    HigherLevelReview.create!(
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
    ineligible = Constants.INELIGIBLE_REQUEST_ISSUES

    let!(:eligible_request_issue) do
      RequestIssue.create!(
        review_request: higher_level_review,
        issue_category: "Military Retired Pay",
        nonrating_issue_description: "eligible nonrating description",
        contention_reference_id: "1234",
        ineligible_reason: nil,
        benefit_type: "compensation",
        decision_date: Date.new(2018, 5, 1)
      )
    end

    let!(:untimely_request_issue) do
      RequestIssue.create!(
        review_request: higher_level_review,
        issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "untimely nonrating description",
        contention_reference_id: "12345",
        benefit_type: "compensation",
        ineligible_reason: :untimely
      )
    end

    let!(:ri_in_review) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        review_request: another_higher_level_review,
        contested_issue_description: "PTSD denied",
        contention_reference_id: "123",
        benefit_type: "compensation",
        ineligible_reason: nil,
        removed_at: nil
      )
    end

    let!(:ri_with_active_previous_review) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        review_request: higher_level_review,
        contested_issue_description: "PTSD denied",
        contention_reference_id: "111",
        ineligible_reason: :duplicate_of_rating_issue_in_active_review,
        benefit_type: "compensation",
        ineligible_due_to: ri_in_review
      )
    end

    let!(:ri_previous_hlr) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "abc123",
        contested_rating_issue_profile_date: rating.profile_date,
        review_request: another_higher_level_review,
        benefit_type: "compensation",
        contested_issue_description: "Left knee granted",
        contention_reference_id: 55
      )
    end

    let!(:ri_with_previous_hlr) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "abc123",
        contested_rating_issue_profile_date: rating.profile_date,
        review_request: higher_level_review,
        contested_issue_description: "Left knee granted",
        benefit_type: "compensation",
        ineligible_reason: :higher_level_review_to_higher_level_review,
        ineligible_due_to: ri_previous_hlr
      )
    end

    let!(:ri_before_ama) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "before_ama_ref_id",
        contested_rating_issue_profile_date: rating_before_ama.profile_date,
        review_request: higher_level_review,
        benefit_type: "compensation",
        contested_issue_description: "Non-RAMP Issue before AMA Activation",
        contention_reference_id: "12345",
        ineligible_reason: :before_ama
      )
    end

    let!(:eligible_ri_before_ama) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "ramp_ref_id",
        contested_rating_issue_profile_date: rating_before_ama_from_ramp.profile_date,
        review_request: higher_level_review,
        benefit_type: "compensation",
        contested_issue_description: "Issue before AMA Activation from RAMP",
        contention_reference_id: "123456",
        ramp_claim_id: "ramp_claim_id"
      )
    end

    let!(:ri_legacy_issue_not_withdrawn) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "has_legacy_issue",
        contested_rating_issue_profile_date: rating_before_ama.profile_date,
        review_request: higher_level_review,
        contested_issue_description: "Issue with legacy issue not withdrawn",
        vacols_id: "vacols1",
        benefit_type: "compensation",
        vacols_sequence_id: "1",
        contention_reference_id: "1234567",
        ineligible_reason: :legacy_issue_not_withdrawn
      )
    end

    let!(:ri_legacy_issue_ineligible) do
      RequestIssue.create!(
        contested_rating_issue_reference_id: "has_ineligible_legacy_appeal",
        contested_rating_issue_profile_date: rating_before_ama.profile_date,
        review_request: higher_level_review,
        contested_issue_description: "Issue connected to ineligible legacy appeal",
        contention_reference_id: "12345678",
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

    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
      another_higher_level_review.create_issues!([ri_in_review])
      higher_level_review.create_issues!([
                                           eligible_request_issue,
                                           untimely_request_issue,
                                           ri_with_active_previous_review,
                                           ri_with_previous_hlr,
                                           ri_before_ama,
                                           eligible_ri_before_ama,
                                           ri_legacy_issue_not_withdrawn,
                                           ri_legacy_issue_ineligible
                                         ])
      higher_level_review.establish!
    end

    context "VACOLS issue from before AMA opted in" do
      let!(:ri_legacy_issue_eligible) do
        RequestIssue.create!(
          contested_rating_issue_reference_id: "before_ama_ref_id",
          contested_rating_issue_profile_date: rating_before_ama.profile_date,
          review_request: higher_level_review,
          contested_issue_description: "Non-RAMP Issue before AMA Activation legacy",
          contention_reference_id: "12345678",
          vacols_id: "vacols1",
          benefit_type: "compensation",
          vacols_sequence_id: "2"
        )
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
          "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
        )
        expect(page).to have_content("#{eligible_request_issue.contention_text} Decision date: 05/01/2018")
        expect(page).to have_content(
          "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
        )
        expect(page).to have_content(
          "#{eligible_ri_before_ama.contention_text} Decision date:"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_not_withdrawn.contention_text} #{ineligible.legacy_issue_not_withdrawn}"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_ineligible.contention_text} #{ineligible.legacy_appeal_not_eligible}"
        )
        expect(page).to have_content(
          "#{ri_legacy_issue_eligible.contention_text} Decision date:"
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
      click_remove_intake_issue(ri_legacy_issue_not_withdrawn_num)
      click_remove_issue_confirmation

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
      click_remove_intake_issue(ri_with_previous_hlr_issue_num)
      click_remove_issue_confirmation

      expect(page).to_not have_content(
        "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_with_previous_hlr.contention_text)
      add_intake_rating_issue("None of these match")

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{ri_with_previous_hlr.contention_text} #{ineligible.higher_level_review_to_higher_level_review}"
      )

      # 5
      ri_in_review_issue_num = find_intake_issue_number_by_text(ri_in_review.contention_text)
      expect_ineligible_issue(ri_in_review_issue_num)
      click_remove_intake_issue(ri_in_review_issue_num)
      click_remove_issue_confirmation

      expect(page).to_not have_content(
        "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_in_review.contention_text)
      add_intake_rating_issue("None of these match")

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{ri_in_review.contention_text} is ineligible because it's already under review as a Higher-Level Review"
      )

      # 6
      untimely_request_issue_num = find_intake_issue_number_by_text(untimely_request_issue.contention_text)
      expect_ineligible_issue(untimely_request_issue_num)
      click_remove_intake_issue(untimely_request_issue_num)
      click_remove_issue_confirmation

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
      add_intake_rating_issue("None of these match")
      add_untimely_exemption_response("No", "I am a nonrating exemption note")

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{untimely_request_issue.contention_text} #{ineligible.untimely}"
      )

      # 7
      ri_before_ama_num = find_intake_issue_number_by_text(ri_before_ama.contention_text)
      expect_ineligible_issue(ri_before_ama_num)
      click_remove_intake_issue(ri_before_ama_num)
      click_remove_issue_confirmation

      expect(page).to_not have_content(
        "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
      )

      click_intake_add_issue
      add_intake_rating_issue(ri_before_ama.contention_text)
      add_intake_rating_issue("None of these match")

      expect_ineligible_issue(number_of_issues)
      expect(page).to have_content(
        "#{ri_before_ama.contention_text} #{ineligible.before_ama}"
      )
    end
  end

  context "Nonrating issue with untimely date and VACOLS opt-in" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
      higher_level_review.reload # get UUID
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

      expect(page).to have_content(Constants.INTAKE_STRINGS.adding_this_issue_vacols_optin)
    end
  end

  context "when there is a nonrating end product" do
    let!(:nonrating_request_issue) do
      RequestIssue.create!(
        review_request: higher_level_review,
        issue_category: "Military Retired Pay",
        nonrating_issue_description: "nonrating description",
        contention_reference_id: "1234",
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
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "A description!",
        date: "04/26/2018"
      )

      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Drill Pay Adjustments",
        description: "A nonrating issue before AMA",
        date: "10/25/2017"
      )

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
               review_request: another_higher_level_review)
      end

      before do
        another_higher_level_review.create_issues!([active_nonrating_request_issue])
      end

      scenario "shows ineligibility message and saves conflicting request issue id" do
        visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"
        click_intake_add_issue
        click_intake_no_matching_issues

        click_dropdown(text: active_nonrating_request_issue.issue_category)
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
          "/higher_level_reviews/#{nonrating_ep_claim_id}/edit/confirmation"
        )

        expect(
          RequestIssue.find_by(
            review_request: higher_level_review,
            issue_category: active_nonrating_request_issue.issue_category,
            ineligible_due_to: active_nonrating_request_issue.id,
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
          review_request: higher_level_review
        )
      end

      before do
        higher_level_review.create_issues!([active_nonrating_request_issue])
        active_nonrating_request_issue.remove_from_review
        higher_level_review.reload
      end

      it "does not appear as a potential match on edit" do
        visit "higher_level_reviews/#{nonrating_ep_claim_id}/edit"
        click_intake_add_issue
        click_intake_no_matching_issues
        click_dropdown(text: active_nonrating_request_issue.issue_category)

        expect(page).to have_content("Does issue 2 match any of these issue categories?")
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
        review_request: higher_level_review
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

      expect(page).to have_content("Add / Remove Issues")

      click_intake_add_issue
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "Description for Active Duty Adjustments",
        date: "04/19/2018"
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
        review_request: higher_level_review,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: rating.profile_date,
        contested_issue_description: "PTSD denied"
      )
    end

    before do
      higher_level_review.create_issues!(request_issues)
      higher_level_review.establish!
      higher_level_review.reload
    end

    it "does not mention VBMS when removing an issue" do
      visit "/higher_level_reviews/#{higher_level_review.uuid}/edit"
      expect(page).to have_content(request_issue.contested_issue_description)

      click_remove_intake_issue_by_text(request_issue.contested_issue_description)
      expect(page).to have_content("The contention you selected will be removed from the decision review.")
    end
  end

  context "when there is a rating end product" do
    let(:contention_ref_id) { "123" }
    let!(:request_issue) do
      create(
        :request_issue,
        review_request: higher_level_review,
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

    context "has decision issues" do
      let(:contested_decision_issues) { setup_prior_decision_issues(veteran) }

      let(:decision_request_issue) do
        create(
          :request_issue,
          review_request: higher_level_review,
          contested_issue_description: "currently contesting decision issue",
          decision_date: Time.zone.now - 2.days,
          contested_decision_issue_id: contested_decision_issues.first.id
        )
      end

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

      it "does not remove & readd unedited issues" do
        verify_request_issue_contending_decision_issue_not_readded(
          "higher_level_reviews/#{rating_ep_claim_id}/edit",
          higher_level_review,
          decision_request_issue.decision_issues + nonrating_decision_request_issue.decision_issues
        )
      end
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
      click_remove_intake_issue("1")
      click_remove_issue_confirmation
      expect(page).not_to have_content("PTSD denied")

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
        date: "04/25/2018"
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
      add_untimely_exemption_response("No", "I am a nonrating exemption note")
      expect(page).to have_content("4 issues")
      expect(page).to have_content("I am a nonrating exemption note")
      expect(page).to have_content("Another Description for Active Duty Adjustments")

      # add unidentified issue
      click_intake_add_issue
      add_intake_unidentified_issue("This is an unidentified issue")
      expect(page).to have_content("5 issues")
      expect(page).to have_content("This is an unidentified issue")
      expect(find_intake_issue_by_number(5)).to have_css(".issue-unidentified")
      expect_ineligible_issue(5)

      # add issue before AMA
      click_intake_add_issue
      add_intake_rating_issue("Non-RAMP Issue before AMA Activation")
      expect(page).to have_content(
        "Non-RAMP Issue before AMA Activation #{Constants.INELIGIBLE_REQUEST_ISSUES.before_ama}"
      )
      expect_ineligible_issue(6)

      # add RAMP issue before AMA
      click_intake_add_issue
      add_intake_rating_issue("Issue before AMA Activation from RAMP")
      expect(page).to have_content("Issue before AMA Activation from RAMP Decision date:")

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
        review_request: higher_level_review,
        issue_category: "Active Duty Adjustments",
        decision_date: 1.month.ago,
        nonrating_issue_description: "Description for Active Duty Adjustments"
      )

      expect(active_duty_adjustments_request_issue.untimely?).to eq(false)

      another_active_duty_adjustments_request_issue = RequestIssue.find_by!(
        review_request: higher_level_review,
        issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "Another Description for Active Duty Adjustments"
      )

      expect(another_active_duty_adjustments_request_issue.untimely?).to eq(true)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption?).to eq(false)
      expect(another_active_duty_adjustments_request_issue.untimely_exemption_notes).to_not be_nil

      expect(
        RequestIssue.find_by(
          review_request: higher_level_review,
          unidentified_issue_text: "This is an unidentified issue"
        )
      ).to_not be_nil

      expect(
        RequestIssue.find_by(
          review_request: higher_level_review,
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
      expect(higher_level_review.reload.open_request_issues).to_not include(request_issue)

      new_version_of_request_issue = higher_level_review.request_issues.find do |ri|
        ri.description == request_issue.description
      end

      expect(new_version_of_request_issue.contested_rating_issue_reference_id).to eq(
        request_issue.contested_rating_issue_reference_id
      )

      # expect contentions to reflect issue update
      existing_contention = rating_epe.contentions.first
      expect(existing_contention.text).to eq("PTSD denied")
      expect(Fakes::VBMSService).to have_received(:remove_contention!).once.with(existing_contention)

      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran.file_number,
        claim_id: rating_epe.reference_id,
        contentions: array_including(
          { description: RequestIssue::UNIDENTIFIED_ISSUE_MSG },
          { description: "Left knee granted" },
          { description: "Issue before AMA Activation from RAMP" },
          description: "PTSD denied"
        ),
        user: current_user
      )

      expect(Fakes::VBMSService).to have_received(:create_contentions!).once.with(
        veteran_file_number: veteran.file_number,
        claim_id: nonrating_epe.reference_id,
        contentions: [{ description: "Active Duty Adjustments - Description for Active Duty Adjustments" }],
        user: current_user
      )
    end

    it "enables save button only when dirty" do
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"

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
      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      click_remove_intake_issue("1")
      click_remove_issue_confirmation

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

      visit "higher_level_reviews/#{rating_ep_claim_id}/edit"
      click_remove_intake_issue("1")
      click_remove_issue_confirmation
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

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
      new_request_issue = higher_level_review.reload.open_request_issues.first
      expect(new_request_issue.description).to eq("Left knee granted")
      expect(request_issue.reload.review_request_id).to_not be_nil
      expect(request_issue).to be_closed
      expect(request_issue.removed_at).to eq(Time.zone.now)
      expect(request_issue.closed_at).to eq(Time.zone.now)
      expect(request_issue.closed_status).to eq("removed")
      expect(request_issue).to be_removed
      expect(new_request_issue.rating_issue_associated_at).to eq(Time.zone.now)

      # expect contentions to reflect issue update
      expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
        veteran_file_number: veteran.file_number,
        claim_id: rating_ep_claim_id,
        contentions: [{ description: "Left knee granted" }],
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

    feature "with cleared end product" do
      let!(:cleared_end_product) do
        create(:end_product_establishment,
               source: higher_level_review,
               synced_status: "CLR")
      end

      scenario "prevents edits on eps that have cleared" do
        visit "higher_level_reviews/#{rating_ep_claim_id}/edit/"
        expect(page).to have_current_path("/higher_level_reviews/#{rating_ep_claim_id}/edit/cleared_eps")
        expect(page).to have_content("Issues Not Editable")
        expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
      end
    end
  end
end
