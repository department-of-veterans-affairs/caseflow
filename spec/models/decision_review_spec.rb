describe DecisionReview do
  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:participant_id) { "1234" }
  let(:veteran) { create(:veteran, participant_id: participant_id) }
  let(:higher_level_review) do
    create(:higher_level_review, veteran_file_number: veteran.file_number, receipt_date: receipt_date)
  end

  let(:supplemental_claim) do
    create(:supplemental_claim, veteran_file_number: veteran.file_number, receipt_date: receipt_date)
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
    Generators::Rating.build(
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
             participant_id: participant_id,
             rating_issue_reference_id: "123",
             decision_text: "decision issue 1",
             benefit_type: higher_level_review.benefit_type,
             profile_date: profile_date,
             decision_review: higher_level_review),
      create(:decision_issue,
             participant_id: participant_id,
             rating_issue_reference_id: "789",
             decision_text: "decision issue 2",
             benefit_type: higher_level_review.benefit_type,
             profile_date: profile_date + 1.day,
             decision_review: higher_level_review),
      create(:decision_issue,
             participant_id: participant_id,
             rating_issue_reference_id: nil,
             decision_text: "decision issue 3",
             benefit_type: higher_level_review.benefit_type,
             profile_date: profile_date + 2.days,
             decision_review: higher_level_review),
      create(:decision_issue,
             participant_id: participant_id,
             rating_issue_reference_id: "appeal123",
             decision_text: "appeal decision issue",
             benefit_type: higher_level_review.benefit_type,
             profile_date: profile_date + 3.days,
             description: "test",
             decision_review: appeal)
    ]
  end

  context "#contestable_issues" do
    subject { higher_level_review.contestable_issues }

    it "creates a list of contestable rating and decision issues" do
      expect(subject.map(&:serialize)).to include(
        { # this rating issue got replaced with a decision issue
          ratingIssueReferenceId: "123",
          ratingIssueProfileDate: profile_date,
          decisionIssueId: decision_issues.first.id,
          date: profile_date,
          description: "decision issue 1",
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: "HigherLevelReview",
          timely: true
        },
        {
          ratingIssueReferenceId: "456",
          ratingIssueProfileDate: profile_date,
          decisionIssueId: nil,
          date: profile_date,
          description: "rating issue 2",
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: nil,
          timely: true
        },
        {
          ratingIssueReferenceId: "789",
          ratingIssueProfileDate: profile_date + 1.day,
          decisionIssueId: decision_issues.second.id,
          date: profile_date + 1.day,
          description: "decision issue 2",
          rampClaimId: nil,
          titleOfActiveReview: nil,
          sourceReviewType: "HigherLevelReview",
          timely: true
        },
        ratingIssueReferenceId: nil,
        ratingIssueProfileDate: profile_date + 2.days,
        decisionIssueId: decision_issues.third.id,
        date: profile_date + 2.days,
        description: "decision issue 3",
        rampClaimId: nil,
        titleOfActiveReview: nil,
        sourceReviewType: "HigherLevelReview",
        timely: true
      )
    end

    context "when an issue was decided in the future" do
      let!(:future_decision_issue) do
        create(:decision_issue,
               decision_review: supplemental_claim,
               profile_date: receipt_date + 1.day,
               benefit_type: supplemental_claim.benefit_type,
               decision_text: "something was decided in the future",
               description: "future decision issue",
               participant_id: veteran.participant_id)
      end

      let!(:future_rating) do
        Generators::Rating.build(
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

      it "does not return Decision Issues in the future" do
        expect(subject.map(&:serialize)).to include(hash_including(description: "decision issue 3"))
        expect(subject.map(&:serialize)).to_not include(hash_including(description: "future decision issue"))
        expect(subject.map(&:serialize)).to include(hash_including(description: "rating issue 2"))
        expect(subject.map(&:serialize)).to_not include(hash_including(description: "future rating issue 2"))
      end
    end

    context "when the issue is from an Appeal that is not outcoded" do
      let(:outcoded_appeal) { create(:appeal, :outcoded, veteran: veteran, receipt_date: receipt_date) }

      let!(:active_appeal_decision_issue) do
        create(:decision_issue,
               decision_review: appeal,
               profile_date: profile_date,
               benefit_type: appeal.benefit_type,
               decision_text: "my appeal isn't outcoded yet",
               description: "active appeal issue",
               participant_id: veteran.participant_id)
      end

      let!(:outcoded_appeal_decision_issue) do
        create(:decision_issue,
               decision_review: outcoded_appeal,
               profile_date: profile_date,
               benefit_type: appeal.benefit_type,
               decision_text: "my appeal is outcoded",
               description: "completed appeal issue",
               participant_id: veteran.participant_id)
      end

      it "does not return the issue in contestable issues" do
        expect(subject.map(&:serialize)).to include(hash_including(description: "completed appeal issue"))
        expect(subject.map(&:serialize)).to_not include(hash_including(description: "active appeal issue"))
      end
    end
  end
end
