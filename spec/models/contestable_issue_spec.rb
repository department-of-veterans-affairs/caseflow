describe ContestableIssue do
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
  let(:rating_issue) do
    RatingIssue.new(
      reference_id: "NBA",
      participant_id: "123",
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
      promulgation_date: promulgation_date,
      description: "this is a good decision",
      benefit_type: benefit_type,
      caseflow_decision_date: caseflow_decision_date
    )
  end

  context ".from_rating_issue" do
    subject { ContestableIssue.from_rating_issue(rating_issue, decision_review) }

    it "can be serialized" do
      contestable_issue = subject
      expect(contestable_issue).to have_attributes(
        rating_issue_reference_id: rating_issue.reference_id,
        rating_issue_profile_date: profile_date,
        decision_issue_id: nil,
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
        decisionIssueId: nil,
        approxDecisionDate: promulgation_date,
        description: rating_issue.decision_text,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: nil,
        timely: true
      )
    end

    context "is untimely" do
      let(:promulgation_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingIssueReferenceId: rating_issue.reference_id,
          ratingIssueProfileDate: profile_date,
          ratingIssueDiagnosticCode: diagnostic_code,
          decisionIssueId: nil,
          approxDecisionDate: promulgation_date,
          description: rating_issue.decision_text,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: nil,
          timely: false
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
        decision_issue_id: decision_issue.id,
        approx_decision_date: caseflow_decision_date,
        description: decision_issue.description,
        source_request_issues: decision_issue.request_issues.open,
        contesting_decision_review: decision_review,
        source_review_type: "Appeal"
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: "rating1",
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: nil,
        decisionIssueId: decision_issue.id,
        approxDecisionDate: caseflow_decision_date,
        description: decision_issue.description,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: "Appeal",
        timely: true
      )
    end

    context "is untimely" do
      let(:caseflow_decision_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingIssueReferenceId: "rating1",
          ratingIssueProfileDate: profile_date,
          ratingIssueDiagnosticCode: nil,
          decisionIssueId: decision_issue.id,
          approxDecisionDate: caseflow_decision_date,
          description: decision_issue.description,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: "Appeal",
          timely: false
        )
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

    context "when there are no conflicting request issues" do
      it { is_expected.to be_nil }
    end

    context "when there are conflicting request issues on a decision issue" do
      let(:contestable_issue) do
        ContestableIssue.from_decision_issue(decision_issue, decision_review)
      end

      context "when the conflicting request issue is on another decision review" do
        let!(:conflicting_request_issue) do
          create(:request_issue, contested_decision_issue: decision_issue)
        end

        it { is_expected.to eq(conflicting_request_issue.review_title) }
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
        create(:request_issue, contested_rating_issue_reference_id: rating_issue.reference_id)
      end

      it { is_expected.to eq(conflicting_request_issue.review_title) }
    end
  end
end
