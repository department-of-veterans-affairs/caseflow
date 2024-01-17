# frozen_string_literal: true

describe ContestableIssue, :postgres do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:decision_review) do
    create(
      :higher_level_review,
      :with_end_product_establishment, # We need this for the status_active? check, but remove when that's refactored
      receipt_date: Time.zone.now,
      benefit_type: benefit_type
    )
  end

  let(:benefit_type) { "compensation" }
  let(:caseflow_decision_date) { Time.zone.today - 20 }
  let(:profile_date) { Time.zone.today }
  let(:promulgation_date) { Time.zone.today - 30 }
  let(:diagnostic_code) { "diagnostic_code" }
  let(:participant_id) { "123" }
  let(:rating_issue) do
    RatingIssue.new(
      reference_id: "NBA",
      participant_id: participant_id,
      profile_date: profile_date,
      promulgation_date: promulgation_date,
      diagnostic_code: diagnostic_code,
      decision_text: "This broadcast may not be reproduced",
      associated_end_products: [],
      rba_contentions_data: [{}]
    )
  end

  let(:decision_issue) do
    create(
      :decision_issue,
      decision_review: create(:appeal),
      rating_issue_reference_id: "rating1",
      rating_promulgation_date: promulgation_date,
      rating_profile_date: profile_date,
      description: "this is a good decision",
      benefit_type: benefit_type,
      caseflow_decision_date: caseflow_decision_date
    )
  end

  let(:rating_decision) do
    RatingDecision.new(
      profile_date: profile_date,
      promulgation_date: promulgation_date,
      begin_date: promulgation_date - 1.day,
      rating_sequence_number: "1234",
      disability_id: "5678",
      diagnostic_text: "tinnitus",
      diagnostic_code: diagnostic_code,
      participant_id: participant_id,
      benefit_type: benefit_type
    )
  end

  context ".from_rating_decision" do
    subject { described_class.from_rating_decision(rating_decision, decision_review) }

    it "can be serialized" do
      contestable_issue = subject
      expect(contestable_issue).to have_attributes(
        rating_issue_reference_id: nil,
        rating_issue_profile_date: profile_date,
        decision_issue: nil,
        approx_decision_date: rating_decision.decision_date,
        description: rating_decision.decision_text,
        contesting_decision_review: decision_review,
        rating_issue_diagnostic_code: diagnostic_code,
        source_review_type: nil
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: nil,
        ratingDecisionReferenceId: rating_decision.reference_id,
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: diagnostic_code,
        decisionIssueId: nil,
        approxDecisionDate: rating_decision.decision_date,
        description: rating_decision.decision_text,
        isRating: true,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: nil,
        timely: true,
        latestIssuesInChain: [{ id: nil, approxDecisionDate: rating_decision.decision_date }]
      )
    end
  end

  context ".from_rating_issue" do
    subject { ContestableIssue.from_rating_issue(rating_issue, decision_review) }

    it "can be serialized" do
      contestable_issue = subject
      expect(contestable_issue).to have_attributes(
        rating_issue_reference_id: rating_issue.reference_id,
        rating_issue_profile_date: profile_date,
        decision_issue: nil,
        approx_decision_date: promulgation_date,
        description: rating_issue.decision_text,
        contesting_decision_review: decision_review,
        rating_issue_diagnostic_code: diagnostic_code,
        source_review_type: nil
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: rating_issue.reference_id,
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: diagnostic_code,
        ratingDecisionReferenceId: nil,
        decisionIssueId: nil,
        approxDecisionDate: promulgation_date,
        description: rating_issue.decision_text,
        isRating: true,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: nil,
        timely: true,
        latestIssuesInChain: [{ id: nil, approxDecisionDate: promulgation_date }]
      )
    end

    context "is untimely" do
      let(:promulgation_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingIssueReferenceId: rating_issue.reference_id,
          ratingIssueProfileDate: profile_date,
          ratingIssueDiagnosticCode: diagnostic_code,
          ratingDecisionReferenceId: nil,
          decisionIssueId: nil,
          approxDecisionDate: promulgation_date,
          description: rating_issue.decision_text,
          isRating: true,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: nil,
          timely: false,
          latestIssuesInChain: [{ id: nil, approxDecisionDate: promulgation_date }]
        )
      end
    end
  end

  context ".from_decision_issue" do
    subject { ContestableIssue.from_decision_issue(decision_issue, decision_review) }

    it "can be serialized" do
      contestable_issue = subject
      expect(contestable_issue).to have_attributes(
        rating_issue_reference_id: "rating1",
        rating_issue_profile_date: profile_date,
        decision_issue: decision_issue,
        approx_decision_date: caseflow_decision_date,
        description: decision_issue.description,
        source_request_issues: decision_issue.request_issues.active,
        contesting_decision_review: decision_review,
        source_review_type: "Appeal"
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: "rating1",
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: nil,
        ratingDecisionReferenceId: nil,
        decisionIssueId: decision_issue.id,
        approxDecisionDate: caseflow_decision_date,
        description: decision_issue.description,
        isRating: true,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: "Appeal",
        timely: true,
        latestIssuesInChain: [{ id: decision_issue.id, approxDecisionDate: caseflow_decision_date }]
      )
    end

    context "is untimely" do
      let(:caseflow_decision_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingIssueReferenceId: "rating1",
          ratingIssueProfileDate: profile_date,
          ratingIssueDiagnosticCode: nil,
          ratingDecisionReferenceId: nil,
          decisionIssueId: decision_issue.id,
          approxDecisionDate: caseflow_decision_date,
          description: decision_issue.description,
          isRating: true,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: "Appeal",
          timely: false,
          latestIssuesInChain: [{ id: decision_issue.id, approxDecisionDate: caseflow_decision_date }]
        )
      end
    end
  end

  context "#latest_contestable_issues" do
    let!(:rating_contestable_issue) { ContestableIssue.from_rating_issue(rating_issue, decision_review) }
    let(:contesting_decision_issue) do
      request_issue = create(:request_issue,
                             decision_review: decision_review,
                             contested_rating_issue_reference_id: rating_contestable_issue.rating_issue_reference_id,
                             contested_rating_issue_profile_date: rating_contestable_issue.rating_issue_profile_date,
                             contested_decision_issue_id: nil)

      create(:decision_issue,
             decision_review: decision_review,
             description: "decision issue for initial request issue",
             request_issues: [request_issue])
    end

    subject { contestable_issue.latest_contestable_issues }

    context "when there are no future decision issues" do
      context "contestable issue is created from a rating issue" do
        let(:contestable_issue) { rating_contestable_issue }

        it "finds current contestable issue" do
          expect(subject.length).to eq(1)
          expect(subject.first.rating_issue_reference_id).to eq(contestable_issue.rating_issue_reference_id)
        end
      end

      context "contestable issue is created from a decision issue" do
        let(:contestable_issue) { ContestableIssue.from_decision_issue(contesting_decision_issue, decision_review) }

        it "finds current contestable issue" do
          expect(subject.length).to eq(1)
          expect(subject.first.decision_issue.id).to eq(contestable_issue.decision_issue.id)
        end
      end
    end

    context "when there is a future decision issue" do
      let(:contestable_issue) { rating_contestable_issue }
      let!(:future_contestable_issues) do
        contestable_issues = []
        contesting_decision_issue_id = contesting_decision_issue.id
        3.times do |index|
          future_appeal = create(:appeal)
          future_request_issue = create(:request_issue,
                                        decision_review: future_appeal,
                                        contested_decision_issue_id: contesting_decision_issue_id)
          future_decision_issue = create(:decision_issue,
                                         decision_review: future_appeal,
                                         description: "decision issue #{index}",
                                         request_issues: [future_request_issue])
          contesting_decision_issue_id = future_decision_issue.id
          contestable_issues << ContestableIssue.from_decision_issue(future_decision_issue, future_appeal)
        end

        contestable_issues
      end

      it "finds the latest contestable issue" do
        expect(subject.length).to eq(1)
        expect(subject.first.decision_issue.id).to eq(future_contestable_issues.last.decision_issue.id)
      end

      context "when there are multiple future decision issues" do
        # one request issue can have multiple decisions
        let!(:another_contestable_issue) do
          decision_issue = create(:decision_issue,
                                  decision_review: future_contestable_issues.second.contesting_decision_review,
                                  description: "another decision issue",
                                  request_issues: future_contestable_issues.second.source_request_issues)
          ContestableIssue.from_decision_issue(decision_issue,
                                               future_contestable_issues.second.contesting_decision_review)
        end

        it "finds both latest contestable issues" do
          expect(subject.length).to eq(2)
          expect(subject.map(&:decision_issue).map(&:id)).to include(another_contestable_issue.decision_issue.id,
                                                                     future_contestable_issues.last.decision_issue.id)
        end
      end
    end
  end

  context "#source_review_type" do
    subject { contestable_issue.source_review_type }

    context "when rating issue" do
      let(:contestable_issue) do
        ContestableIssue.from_rating_issue(rating_issue, decision_review)
      end

      it { is_expected.to be_nil }
    end

    context "when decision issue" do
      let(:contestable_issue) do
        ContestableIssue.from_decision_issue(decision_issue, decision_review)
      end

      it { is_expected.to eq("Appeal") }
    end
  end

  context "#title_of_active_review" do
    subject { contestable_issue.title_of_active_review }

    let(:contestable_issue) do
      ContestableIssue.from_rating_issue(rating_issue, decision_review)
    end

    let(:closed_at) { nil }

    context "when there are no conflicting request issues" do
      it { is_expected.to be_nil }
    end

    context "when there are conflicting request issues on a decision issue" do
      let(:contestable_issue) do
        ContestableIssue.from_decision_issue(decision_issue, decision_review)
      end

      context "when the conflicting request issue is on another decision review" do
        let!(:conflicting_request_issue) do
          create(
            :request_issue,
            contested_decision_issue: decision_issue,
            closed_at: closed_at
          )
        end

        it { is_expected.to eq(conflicting_request_issue.review_title) }

        context "when conflicting request issue is closed" do
          let(:closed_at) { Time.zone.now }

          it { is_expected.to be_nil }
        end
      end

      context "when the conflicting request issue is on the same decision review" do
        let!(:conflicting_request_issue) do
          create(:request_issue, contested_decision_issue: decision_issue, decision_review: decision_review)
        end

        it { is_expected.to be_nil }
      end
    end

    context "when there are conflicting request issues on a rating issue" do
      let!(:conflicting_request_issue) do
        create(
          :request_issue,
          contested_rating_issue_reference_id: rating_issue.reference_id,
          closed_at: closed_at
        )
      end

      it { is_expected.to eq(conflicting_request_issue.review_title) }

      context "when conflicting request issue is closed" do
        let(:closed_at) { Time.zone.now }

        it { is_expected.to be_nil }
      end
    end
  end

  context "#timely?" do
    subject { ContestableIssue.from_rating_issue(rating_issue, decision_review) }

    it "should equal true" do
      expect(subject.timely?).to eq true
    end

    context "when untimely" do
      let(:promulgation_date) { Time.zone.today - 373.days }
      it "should equal false" do
        expect(subject.timely?).to eq false
      end
    end
  end
end
