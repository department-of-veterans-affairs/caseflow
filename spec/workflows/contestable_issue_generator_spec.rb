# frozen_string_literal: true

describe "Contestable Issue Generator", :postgres do
  let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let(:review) { hlr }
  let(:veteran) { create(:veteran) }
  let(:past_decision_date) { review.receipt_date - 1.day }
  let!(:past_rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: past_decision_date,
      profile_date: past_decision_date,
      issues: [
        { reference_id: "abc123", decision_text: "Rating issue" }
      ],
      decisions: [
        {
          rating_issue_reference_id: nil,
          original_denial_date: past_decision_date,
          diagnostic_text: "Right arm broken",
          diagnostic_type: "Bone",
          disability_id: "123",
          disability_date: past_decision_date,
          type_name: "Not Service Connected"
        },
        {
          rating_issue_reference_id: "abc123",
          original_denial_date: past_decision_date,
          diagnostic_text: "Left arm broken",
          diagnostic_type: "Bone",
          disability_id: "456",
          disability_date: past_decision_date,
          type_name: "Not Service Connected"
        },
        {
          rating_issue_reference_id: "disability_with_new_rating_issue_id",
          original_denial_date: past_decision_date,
          diagnostic_text: "Pinky toe broken",
          diagnostic_type: "Bone",
          disability_id: "123456",
          disability_date: past_decision_date,
          type_name: "Not Service Connected"
        }
      ]
    )
  end

  let(:future_decision_date) { review.receipt_date + 5.days }
  let!(:future_rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: future_decision_date,
      profile_date: future_decision_date,
      issues: [
        { reference_id: "xyz123", decision_text: "Future Rating issue" }
      ],
      decisions: [
        {
          rating_issue_reference_id: nil,
          original_denial_date: future_decision_date,
          diagnostic_text: "Right leg broken",
          diagnostic_type: "Bone",
          disability_id: "666001234",
          disability_date: future_decision_date,
          type_name: "Not Service Connected"
        },
        {
          rating_issue_reference_id: "xyz123",
          original_denial_date: future_decision_date,
          diagnostic_text: "Left leg broken",
          diagnostic_type: "Bone",
          disability_id: "4567",
          disability_date: future_decision_date,
          type_name: "Not Service Connected"
        }
      ]
    )
  end

  let!(:today_rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: review.receipt_date,
      profile_date: review.receipt_date,
      issues: [
        { reference_id: "def456", decision_text: "Rating issue" }
      ]
    )
  end

  let!(:review_decision_issue) do
    create(
      :decision_issue,
      decision_review: review,
      rating_profile_date: review.receipt_date + 1.day,
      end_product_last_action_date: review.receipt_date + 1.day,
      benefit_type: review.benefit_type,
      participant_id: veteran.participant_id,
      decision_text: "review decision issue"
    )
  end

  let!(:another_decision_issue) do
    create(
      :decision_issue,
      decision_review: create(:higher_level_review),
      rating_profile_date: review.receipt_date - 1.day,
      end_product_last_action_date: review.receipt_date - 1.day,
      benefit_type: review.benefit_type,
      participant_id: veteran.participant_id,
      decision_text: "a past decision issue from another review"
    )
  end

  describe "#contestable_issues" do
    subject { ContestableIssueGenerator.new(review).contestable_issues }

    context "when the review cannot contest rating issues" do
      before { allow_any_instance_of(review.class).to receive(:can_contest_rating_issues?).and_return false }

      it "only returns decision issues" do
        expect(subject.count).to eq(1)
        expect(subject.first.description).to eq("a past decision issue from another review")
      end
    end

    context "when correct_claim_reviews feature toggle is enabled" do
      before { FeatureToggle.enable!(:correct_claim_reviews) }
      after { FeatureToggle.disable!(:correct_claim_reviews) }

      it "returns decision issues from the same review" do
        expect(subject.count).to eq(4)
        expect(subject.select { |issue| issue.description == "review decision issue" }.empty?).to be false
      end
    end

    context "when the contestable_rating_decisions Feature Toggle is enabled" do
      before { FeatureToggle.enable!(:contestable_rating_decisions) }
      after { FeatureToggle.disable!(:contestable_rating_decisions) }

      it "returns rating decisions that are not present in rating issues" do
        expect(subject.count).to eq(5)
        descriptions = subject.map(&:description)
        expect(descriptions.grep(/Pinky toe/).count).to eq 1
        expect(descriptions.grep(/Right arm/).count).to eq 1
        expect(descriptions.grep(/Left arm/).count).to eq 0
        expect(descriptions.grep(/leg/).count).to eq 0
      end
    end

    context "when the review is a remand supplemental claim" do
      let(:review) do
        create(
          :supplemental_claim,
          veteran_file_number: veteran.file_number,
          decision_review_remanded: hlr
        )
      end

      it "does not return any contestable issues" do
        expect(subject.empty?).to be true
      end

      context "when correct_claim_reviews feature toggle is enabled" do
        before { FeatureToggle.enable!(:correct_claim_reviews) }
        after { FeatureToggle.disable!(:correct_claim_reviews) }

        it "only returns decision issues from the same review" do
          expect(subject.count).to eq(1)
          expect(subject.first.description).to eq "review decision issue"
        end
      end
    end

    context "#contestable_issues with future ratings" do
      before { FeatureToggle.enable!(:show_future_ratings) }
      after { FeatureToggle.disable!(:show_future_ratings) }

      it "when show_future_ratings feature toggle is enabled" do
        expect(subject.count).to eq(4)
        expect(subject.first.description).to eq "Future Rating issue"
      end
    end

    context "#contestable_issues with no future ratings" do
      it "when show_future_ratings feature toggle is not enabled" do
        expect(subject.count).to eq(3)
        expect(subject.first.description).to eq "Rating issue"
      end
    end
  end
end
