describe ContestableIssue do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:decision_review) { create(:higher_level_review, receipt_date: Time.zone.now, benefit_type: benefit_type) }
  let(:benefit_type) { "compensation" }
  let(:profile_date) { Time.zone.today - 30 }
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
        contesting_decision_review: decision_review,
        rating_issue_diagnostic_code: diagnostic_code
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: rating_issue.reference_id,
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: diagnostic_code,
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
          ratingIssueDiagnosticCode: diagnostic_code,
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
        source_request_issues: decision_issue.request_issues,
        contesting_decision_review: decision_review
      )

      expect(contestable_issue.serialize).to eq(
        ratingIssueReferenceId: "rating1",
        ratingIssueProfileDate: profile_date,
        ratingIssueDiagnosticCode: nil,
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
          ratingIssueDiagnosticCode: nil,
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

  context "#latest_contestable_issues" do
    let!(:rating_contestable_issue) { ContestableIssue.from_rating_issue(rating_issue, decision_review) }
    let(:contesting_decision_issue) do
      request_issue = create(:request_issue,
                             review_request: decision_review,
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
                                        review_request: future_appeal,
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
          ContestableIssue.from_decision_issue(decision_issue, future_contestable_issues.second.contesting_decision_review)
        end

        it "finds both latest contestable issues" do
          expect(subject.length).to eq(2)
          expect(subject.map(&:decision_issue).map(&:id)).to include(another_contestable_issue.decision_issue.id, future_contestable_issues.last.decision_issue.id)
        end
      end
    end
  end
end
