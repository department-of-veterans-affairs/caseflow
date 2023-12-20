# frozen_string_literal: true

describe "Contestable Issue Generator", :postgres do
  let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let(:review) { hlr }
  let(:veteran) { create(:veteran) }
  let!(:past_rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: review.receipt_date - 1.day,
      profile_date: review.receipt_date - 1.day,
      issues: [
        { reference_id: "abc123", decision_text: "Rating issue" }
      ]
    )
  end

  let!(:future_rating) do
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: review.receipt_date + 5.days,
      profile_date: review.receipt_date + 5.days,
      issues: [
        { reference_id: "abc123", decision_text: "Future Rating issue" }
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
