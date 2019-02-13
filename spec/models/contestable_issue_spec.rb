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
  end

  context "#latest_contestable_issues" do
    let(:appeal) { create(:appeal) }
    let(:starting_date) { Time.zone.now - 20.days }
    let!(:request_issue_for_rating) { create(:request_issue, :rating, review_request: appeal) }
    let!(:rating_contestable_issue) do
      rating_issue = RatingIssue.new(
        reference_id: "NBA",
        participant_id: "123",
        profile_date: starting_date - 2.days,
        promulgation_date: starting_date - 3.days,
        decision_text: "This broadcast may not be reproduced",
        associated_end_products: [],
        rba_contentions_data: [{}]
      )

      ContestableIssue.from_rating_issue(rating_issue, appeal)
    end

    let(:contesting_decision_issue) do
      request_issue = create(:request_issue,
                             review_request: appeal,
                             contested_rating_issue_reference_id: rating_contestable_issue.rating_issue_reference_id,
                             contested_rating_issue_profile_date: rating_contestable_issue.rating_issue_profile_date,
                             contested_decision_issue_id: nil)

      create(:decision_issue,
             decision_review: appeal,
             description: "decision issue for initial request issue",
             caseflow_decision_date: starting_date,
             request_issues: [request_issue])
    end

    let!(:another_contestable_issue) do
      another_appeal = create(:appeal)
      request_issue = create(:request_issue,
                             review_request: another_appeal,
                             contested_decision_issue_id: contesting_decision_issue.id)
      decision_issue = create(:decision_issue,
                              decision_review: another_appeal,
                              description: "another decision issue",
                              caseflow_decision_date: starting_date + 1.day,
                              request_issues: [request_issue])
      ContestableIssue.from_decision_issue(decision_issue, another_appeal)
    end

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
                                       caseflow_decision_date: starting_date + index.days,
                                       request_issues: [future_request_issue])
        contesting_decision_issue_id = future_decision_issue.id
        contestable_issues << ContestableIssue.from_decision_issue(future_decision_issue, future_appeal)
      end

      contestable_issues
    end

    # rubocop:disable Metrics/AbcSize
    def check_latest_contestable_issues(latest_contestable_issues)
      # finds another_contestable_issue & the lastest of the future_contestable_issues

      expect(latest_contestable_issues.length).to eq(2)
      found_another_contestable_issue = latest_contestable_issues.find do |issue|
        issue.contesting_decision_review == another_contestable_issue.contesting_decision_review &&
          issue.decision_issue_id == another_contestable_issue.decision_issue_id
      end
      found_future_contestable_issue = latest_contestable_issues.find do |issue|
        issue.contesting_decision_review == future_contestable_issues.last.contesting_decision_review &&
          issue.decision_issue_id == future_contestable_issues.last.decision_issue_id
      end
      expect(found_another_contestable_issue).to_not be_nil
      expect(found_future_contestable_issue).to_not be_nil
    end
    # rubocop:enable Metrics/AbcSize

    context "from the middle of a chain of decision issues" do
      let!(:starting_contestable_issue) do
        ContestableIssue.from_decision_issue(contesting_decision_issue, appeal)
      end
      it "finds latest contestable issues" do
        latest_contestable_issues = starting_contestable_issue.latest_contestable_issues
        check_latest_contestable_issues(latest_contestable_issues)
      end
    end

    context "from a contestable rating issue" do
      it "finds latest contestable issues" do
        latest_contestable_issues = rating_contestable_issue.latest_contestable_issues
        check_latest_contestable_issues(latest_contestable_issues)
      end
    end
  end
end
