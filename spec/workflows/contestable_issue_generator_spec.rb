# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe "Contestable Issue Generator", :postgres do
  let(:review) { create(:higher_level_review) }
  let!(:past_rating) do
    Generators::Rating.build(
      participant_id: review.veteran.participant_id,
      promulgation_date: review.receipt_date - 1.day,
      profile_date: review.receipt_date - 1.day,
      issues: [
        { reference_id: "abc123", decision_text: "Rating issue" }
      ]
    )
  end

  let!(:future_rating) do
    Generators::Rating.build(
      participant_id: review.veteran.participant_id,
      promulgation_date: review.receipt_date + 1.day,
      profile_date: review.receipt_date + 1.day,
      issues: [
        { reference_id: "abc123", decision_text: "Rating issue" }
      ]
    )
  end

  let!(:review_decision_issue) do
    create(
      :decision_issue,
      decision_review: review,
      # rating_profile_date: receipt_date + 1.day,
      # end_product_last_action_date: receipt_date + 1.day,
      # benefit_type: review.benefit_type,
      decision_text: "review decision issue"
    )
  end

  let!(:another_decision_issue) do

  end

  describe "#contestable_issues" do
    subject { ContestableIssueGenerator.new(review).contestable_issues }

    context "when the review cannot contest rating issues" do
      before { allow_any_instance_of(DecisionReview).to receive(:can_contest_rating_issues?).and_return false }

      it "does not return rating issues" do
        expect(subject).to eq(1)
      end
    end
  end
end
