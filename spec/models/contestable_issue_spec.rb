describe ContestableIssue do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:decision_review) { create(:higher_level_review, receipt_date: Time.zone.now) }
  let(:profile_date) { Time.zone.today - 30 }
  let(:promulgation_date) { Time.zone.today - 30 }
  let(:disability_code) { "disability_code" }
  let(:rating_issue) do
    RatingIssue.new(
      reference_id: "NBA",
      participant_id: "123",
      profile_date: profile_date,
      promulgation_date: promulgation_date,
      disability_code: disability_code,
      decision_text: "This broadcast may not be reproduced",
      associated_end_products: [],
      rba_contentions_data: [{}]
    )
  end
  let(:profile_date) { Time.zone.today }
  let(:decision_issue) do
    DecisionIssue.new(
      id: "1",
      rating_issue_reference_id: "rating1",
      profile_date: profile_date,
      description: "this is a good decision"
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
        date: profile_date,
        description: rating_issue.decision_text,
        source_request_issue: rating_issue.source_request_issue,
        contesting_decision_review: decision_review
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: rating_issue.reference_id,
        ratingIssueProfileDate: profile_date,
        ratingIssueDisabilityCode: disability_code,
        decisionIssueId: nil,
        date: profile_date,
        description: rating_issue.decision_text,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: nil,
        timely: true
      )
    end

    context "is untimely" do
      let(:profile_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingIssueReferenceId: rating_issue.reference_id,
          ratingIssueProfileDate: profile_date,
          ratingIssueDisabilityCode: disability_code,
          decisionIssueId: nil,
          date: profile_date,
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
        date: profile_date,
        description: decision_issue.description,
        source_request_issue: decision_issue,
        contesting_decision_review: decision_review
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: "rating1",
        ratingIssueProfileDate: profile_date,
        ratingIssueDisabilityCode: nil,
        decisionIssueId: decision_issue.id,
        date: profile_date,
        description: decision_issue.description,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: nil,
        timely: true
      )
    end

    context "is untimely" do
      let(:profile_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingIssueReferenceId: "rating1",
          ratingIssueProfileDate: profile_date,
          ratingIssueDisabilityCode: nil,
          decisionIssueId: decision_issue.id,
          date: profile_date,
          description: decision_issue.description,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: nil,
          timely: false
        )
      end
    end
  end
end
