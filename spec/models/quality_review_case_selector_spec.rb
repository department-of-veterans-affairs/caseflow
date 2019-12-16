# frozen_string_literal: true

describe QualityReviewCaseSelector, :all_dbs do
  context "after reaching the monthly limit" do
    let!(:qr_tasks) do
      QualityReviewCaseSelector::MONTHLY_LIMIT_OF_QUAILITY_REVIEWS.times do
        QualityReviewTask.create(assigned_to: create(:user), appeal: create(:appeal), created_at: Time.zone.now)
      end
    end

    context ".reached_monthly_limit_in_quality_reviews?"
    it "return true to indicate the limit was reached" do
      expect(QualityReviewCaseSelector.reached_monthly_limit_in_quality_reviews?).to be(true)
    end
  end
end
