describe ContestableIssue do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:decision_review) { create(:higher_level_review, receipt_date: Time.zone.now, benefit_type: benefit_type) }
  let(:benefit_type) { "compensation" }
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
    create(:decision_issue,
           rating_issue_reference_id: "rating1",
           profile_date: profile_date,
           description: "this is a good decision",
           benefit_type: benefit_type)
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
        source_request_issues: rating_issue.source_request_issues,
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

    context "#next_decision_issue" do
      subject { ContestableIssue.from_rating_issue(rating_issue, decision_review).next_decision_issue }
      context "with no future decision issue" do
        it "returns nil" do
          expect(subject).to eq(nil)
        end
      end

      context "with future decision issue" do
        let!(:request_issue) do
          create(:request_issue,
                 review_request: decision_review,
                 contested_rating_issue_reference_id: rating_issue.reference_id,
                 contested_rating_issue_profile_date: rating_issue.profile_date,
                 contested_decision_issue_id: nil)
        end
        let!(:decision_issue) do
          create(:decision_issue,
                 decision_review: decision_review,
                 description: "decision issue for initial request issue",
                 caseflow_decision_date: promulgation_date + 1.day,
                 request_issues: [request_issue])
        end

        it "can find the next decision issue" do
          expect(subject.id).to eq(decision_issue.id)
        end
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
        source_request_issues: decision_issue.request_issues,
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

    context "#next_decision_issue" do
      subject { ContestableIssue.from_decision_issue(decision_issue, decision_review).next_decision_issue }
      context "with no future decision issue" do
        it "returns nil" do
          expect(subject).to eq(nil)
        end
      end

      context "with future decision issue" do
        let!(:request_issue) do
          create(:request_issue,
                 review_request: decision_review,
                 contested_decision_issue_id: decision_issue.id)
        end
        let!(:future_decision_issue) do
          create(:decision_issue,
                 decision_review: decision_review,
                 description: "decision issue for initial request issue",
                 caseflow_decision_date: promulgation_date + 1.day,
                 request_issues: [request_issue])
        end

        it "can find the next decision issue" do
          expect(subject.id).to eq(future_decision_issue.id)
        end
      end
    end
  end
end
