describe ContestableIssue do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:decision_review) { create(:higher_level_review, receipt_date: Time.zone.now) }
  let(:profile_date) { Time.zone.today - 30 }
  let(:promulgation_date) { Time.zone.today - 30 }
  let(:rating_issue) do
    RatingIssue.new(
      reference_id: "NBA",
      participant_id: "123",
      profile_date: profile_date,
      promulgation_date: promulgation_date,
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
      decision_text: "this is a disposition"
    )
  end

  context ".from_rating_issue" do
    subject { ContestableIssue.from_rating_issue(rating_issue, decision_review) }

    it "can be serialized" do
      contestable_issue = subject
      expect(contestable_issue).to have_attributes(
        rating_reference_id: rating_issue.reference_id,
        decision_issue_reference_id: nil,
        date: profile_date,
        description: rating_issue.decision_text,
        contesting_decision_review: decision_review
      )

      expect(contestable_issue.serialize).to eq(
        ratingReferenceId: rating_issue.reference_id,
        decisionIssueReferenceId: nil,
        date: profile_date,
        description: rating_issue.decision_text,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceHigherLevelReview: nil,
        timely: true
      )
    end

    context "is untimely" do
      let(:profile_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingReferenceId: rating_issue.reference_id,
          decisionIssueReferenceId: nil,
          date: profile_date,
          description: rating_issue.decision_text,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceHigherLevelReview: nil,
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
        rating_reference_id: "rating1",
        decision_issue_reference_id: decision_issue.id,
        date: profile_date,
        description: decision_issue.decision_text,
        contesting_decision_review: decision_review
      )

      expect(contestable_issue.serialize).to eq(
        ratingReferenceId: "rating1",
        decisionIssueReferenceId: decision_issue.id,
        date: profile_date,
        description: decision_issue.decision_text,
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceHigherLevelReview: nil,
        timely: true
      )
    end

    context "is untimely" do
      let(:profile_date) { Time.zone.today - 373.days }

      it "can be serialized" do
        expect(subject.serialize).to eq(
          ratingReferenceId: "rating1",
          decisionIssueReferenceId: decision_issue.id,
          date: profile_date,
          description: decision_issue.decision_text,
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceHigherLevelReview: nil,
          timely: false
        )
      end
    end
  end
end
