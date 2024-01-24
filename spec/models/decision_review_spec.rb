# frozen_string_literal: true

describe DecisionReview, :postgres do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:participant_id) { "1234" }
  let(:veteran) { create(:veteran, participant_id: participant_id) }
  let(:higher_level_review) do
    create(:higher_level_review, veteran_file_number: veteran.file_number, receipt_date: receipt_date)
  end
  let(:decision_review_remanded) { nil }
  let(:benefit_type) { "compensation" }
  let(:supplemental_claim) do
    create(
      :supplemental_claim,
      veteran_file_number: veteran.file_number,
      receipt_date: receipt_date,
      decision_review_remanded: decision_review_remanded,
      benefit_type: benefit_type
    )
  end

  let(:receipt_date) { Time.zone.today }

  let(:promulgation_date) { receipt_date - 30 }
  let(:profile_date) { receipt_date - 40 }
  let(:associated_claims) { [] }
  let(:issues) do
    [
      { reference_id: "123", decision_text: "rating issue 1" },
      { reference_id: "456", decision_text: "rating issue 2" }
    ]
  end
  let!(:rating) do
    Generators::PromulgatedRating.build(
      issues: issues,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      participant_id: participant_id,
      associated_claims: associated_claims
    )
  end
  let(:appeal) { create(:appeal) }
  let!(:decision_issues) do
    [
      create(:decision_issue,
             :rating,
             participant_id: participant_id,
             rating_issue_reference_id: "123",
             decision_text: "decision issue 1",
             benefit_type: higher_level_review.benefit_type,
             rating_profile_date: profile_date,
             rating_promulgation_date: promulgation_date,
             decision_review: higher_level_review),
      create(:decision_issue,
             :rating,
             participant_id: participant_id,
             rating_issue_reference_id: "789",
             decision_text: "decision issue 2",
             benefit_type: higher_level_review.benefit_type,
             rating_profile_date: profile_date + 1.day,
             rating_promulgation_date: promulgation_date + 1.day,
             decision_review: higher_level_review),
      create(:decision_issue,
             :nonrating,
             participant_id: participant_id,
             decision_text: "decision issue 3",
             end_product_last_action_date: promulgation_date,
             benefit_type: higher_level_review.benefit_type,
             decision_review: higher_level_review),
      create(:decision_issue,
             :rating,
             participant_id: participant_id,
             rating_issue_reference_id: "appeal123",
             decision_text: "appeal decision issue",
             benefit_type: higher_level_review.benefit_type,
             description: "test",
             decision_review: appeal,
             caseflow_decision_date: profile_date + 3.days)
    ]
  end

  context "#can_contest_rating_issues?" do
    subject { decision_review.can_contest_rating_issues? }

    context "for an appeal" do
      let(:decision_review) { appeal }

      it { is_expected.to eq(true) }
    end

    context "for a claim review" do
      let(:decision_review) { supplemental_claim }

      context "when processed in vbms" do
        it { is_expected.to eq(true) }

        context "when the decision review is a remand supplemental claim" do
          let(:decision_review_remanded) { create(:higher_level_review) }

          it { is_expected.to eq(false) }
        end
      end

      context "when processed in caseflow" do
        let(:benefit_type) { "education" }

        it { is_expected.to eq(false) }
      end
    end
  end

  context "#removed?" do
    subject { higher_level_review.removed? }

    let!(:removed_ri) { create(:request_issue, :removed, decision_review: higher_level_review) }
    let!(:active_ri) { create(:request_issue, decision_review: higher_level_review) }

    context "when a subset of request issues are removed" do
      it { is_expected.to eq(false) }
    end

    context "when all request issues are removed" do
      before { higher_level_review.request_issues.each(&:remove!) }

      it { is_expected.to eq(true) }
    end

    context "when there are no request issues" do
      before { higher_level_review.request_issues.each(&:destroy!) }

      it { is_expected.to eq(false) }
    end
  end

  context "#contestable_issues" do
    subject { supplemental_claim.contestable_issues }

    def find_serialized_issue(serialized_contestable_issues, ref_id_or_description)
      serialized_contestable_issues.find do |i|
        i[:isRating] ? i[:ratingIssueReferenceId] == ref_id_or_description : i[:description] == ref_id_or_description
      end
    end

    it "creates a list of contestable rating and decision issues" do
      serialized_contestable_issues = subject.map(&:serialize)

      expect(find_serialized_issue(serialized_contestable_issues, "123")).to eq(
        # this rating issue got replaced with a decision issue
        ratingIssueReferenceId: "123",
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: nil,
        ratingDecisionReferenceId: nil,
        decisionIssueId: decision_issues.first.id,
        approxDecisionDate: promulgation_date,
        description: "decision issue 1",
        isRating: true,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: "HigherLevelReview",
        timely: true,
        latestIssuesInChain: [{ id: decision_issues.first.id, approxDecisionDate: promulgation_date }]
      )

      expect(find_serialized_issue(serialized_contestable_issues, "456")).to eq(
        ratingIssueReferenceId: "456",
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: nil,
        ratingDecisionReferenceId: nil,
        decisionIssueId: nil,
        approxDecisionDate: promulgation_date,
        description: "rating issue 2",
        isRating: true,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: nil,
        timely: true,
        latestIssuesInChain: [{ id: nil, approxDecisionDate: promulgation_date }]
      )

      expect(find_serialized_issue(serialized_contestable_issues, "789")).to eq(
        ratingIssueReferenceId: "789",
        ratingIssueProfileDate: profile_date + 1.day,
        ratingIssueDiagnosticCode: nil,
        ratingDecisionReferenceId: nil,
        decisionIssueId: decision_issues.second.id,
        approxDecisionDate: promulgation_date + 1.day,
        description: "decision issue 2",
        isRating: true,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: "HigherLevelReview",
        timely: true,
        latestIssuesInChain: [{ id: decision_issues.second.id, approxDecisionDate: promulgation_date + 1.day }]
      )

      expect(find_serialized_issue(serialized_contestable_issues, "decision issue 3")).to eq(
        ratingIssueReferenceId: nil,
        ratingIssueProfileDate: nil,
        ratingIssueDiagnosticCode: nil,
        ratingDecisionReferenceId: nil,
        decisionIssueId: decision_issues.third.id,
        approxDecisionDate: promulgation_date,
        description: "decision issue 3",
        isRating: false,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: "HigherLevelReview",
        timely: true,
        latestIssuesInChain: [{ id: decision_issues.third.id, approxDecisionDate: promulgation_date }]
      )
    end

    context "when an issue was decided in the future" do
      let!(:future_decision_issue) do
        create(:decision_issue,
               decision_review: supplemental_claim,
               rating_profile_date: receipt_date + 1.day,
               end_product_last_action_date: receipt_date + 1.day,
               benefit_type: supplemental_claim.benefit_type,
               decision_text: "something was decided in the future 1",
               description: "future decision issue from same review",
               participant_id: veteran.participant_id)
      end

      let!(:future_decision_issue2) do
        create(:decision_issue,
               decision_review: higher_level_review,
               rating_profile_date: receipt_date + 1.day,
               end_product_last_action_date: receipt_date + 1.day,
               benefit_type: higher_level_review.benefit_type,
               decision_text: "something was decided in the future 2",
               description: "future decision issue from a different review",
               participant_id: veteran.participant_id)
      end

      let!(:future_rating) do
        Generators::PromulgatedRating.build(
          issues: [
            { reference_id: "321", decision_text: "future rating issue 1" },
            { reference_id: "654", decision_text: "future rating issue 2" }
          ],
          promulgation_date: receipt_date + 1,
          profile_date: receipt_date + 1,
          participant_id: participant_id,
          associated_claims: associated_claims
        )
      end

      context "without correct_claim_reviews feature toggle" do
        it "does include decision issues in the future that correspond to same review" do
          expect(subject.map(&:serialize)).to include(hash_including(description: "decision issue 3"))
          expect(subject.map(&:serialize)).to_not include(
            hash_including(description: "future decision issue from same review")
          )
          expect(subject.map(&:serialize)).to_not include(
            hash_including(description: "future decision issue from a different review")
          )
          expect(subject.map(&:serialize)).to include(hash_including(description: "rating issue 2"))
          expect(subject.map(&:serialize)).to_not include(hash_including(description: "future rating issue 2"))
        end
      end

      context "with correct_claim_reviews feature toggle" do
        before { FeatureToggle.enable!(:correct_claim_reviews) }

        it "does include decision issues in the future that correspond to same review" do
          expect(subject.map(&:serialize)).to include(hash_including(description: "decision issue 3"))
          expect(subject.map(&:serialize)).to include(
            hash_including(description: "future decision issue from same review")
          )
          expect(subject.map(&:serialize)).to_not include(
            hash_including(description: "future decision issue from a different review")
          )
          expect(subject.map(&:serialize)).to include(hash_including(description: "rating issue 2"))
          expect(subject.map(&:serialize)).to_not include(hash_including(description: "future rating issue 2"))
        end
      end
    end

    context "when the issue is from an appeal that is not outcoded" do
      let(:outcoded_appeal) { create(:appeal, :outcoded, veteran: veteran, receipt_date: receipt_date) }
      let!(:outcoded_decision_doc) { create(:decision_document, decision_date: profile_date, appeal: outcoded_appeal) }

      let!(:active_appeal_decision_issue) do
        create(:decision_issue,
               decision_review: appeal,
               benefit_type: "compensation",
               decision_text: "my appeal isn't outcoded yet",
               description: "active appeal issue",
               participant_id: veteran.participant_id)
      end

      let!(:outcoded_appeal_decision_issue) do
        create(:decision_issue,
               decision_review: outcoded_appeal,
               benefit_type: "compensation",
               decision_text: "my appeal is outcoded",
               description: "completed appeal issue",
               participant_id: veteran.participant_id,
               caseflow_decision_date: outcoded_decision_doc.decision_date)
      end

      it "does not return the issue in contestable issues" do
        expect(subject.map(&:serialize)).to include(hash_including(description: "completed appeal issue"))
        expect(subject.map(&:serialize)).to_not include(hash_including(description: "active appeal issue"))
      end
    end
  end

  describe ".withdrawn?" do
    it "calls WithdrawnDecisionReviewPolicy" do
      appeal = build_stubbed(:appeal)
      policy = instance_double(WithdrawnDecisionReviewPolicy)

      expect(WithdrawnDecisionReviewPolicy).to receive(:new)
        .with(appeal).and_return(policy)
      expect(policy).to receive(:satisfied?)

      appeal.withdrawn?
    end
  end

  describe "#active_request_issues" do
    it "only returns active request issues" do
      review = build_stubbed(:appeal)
      active_request_issue = create(:request_issue, decision_review: review)
      inactive_request_issue = create(
        :request_issue, closed_at: Time.zone.now, decision_review: review
      )
      withdrawn_request_issue = create(
        :request_issue,
        closed_status: "withdrawn",
        closed_at: Time.zone.now,
        decision_review: review
      )

      expect(review.active_request_issues).to match_array([active_request_issue])
    end
  end

  describe "#withdrawn_request_issues" do
    it "only returns withdrawn request issues" do
      review = build_stubbed(:appeal)
      active_request_issue = create(:request_issue, decision_review: review)
      withdrawn_request_issue = create(
        :request_issue,
        closed_status: "withdrawn",
        closed_at: Time.zone.now,
        decision_review: review
      )
      inactive_request_issue = create(
        :request_issue, closed_at: Time.zone.now, decision_review: review
      )

      expect(review.withdrawn_request_issues).to match_array([withdrawn_request_issue])
    end
  end

  describe "#asyncable_user" do
    it "returns CSS id of the Intake user" do
      intake = create(:intake)
      review = intake.detail
      expect(review.asyncable_user).to eq(review.intake.user)
    end
  end
end
