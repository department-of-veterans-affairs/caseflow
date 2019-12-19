# frozen_string_literal: true

describe QualityReviewCaseSelector, :all_dbs do
  describe ".reached_monthly_limit_in_quality_reviews?" do
    context "when a realistic number of cases are completed" do
      # Pulled from prod with:
      # Task.where(
      #   appeal_type: Appeal.name,
      #   assigned_to_type: Organization.name,
      #   type: [QualityReviewTask.name, BvaDispatchTask.name],
      #   created_at: 2.month.ago.beginning_of_month..2.month.ago.end_of_month
      # ).count
      let(:complete_cases_count) { 850 }
      let!(:qr_tasks) do
        complete_cases_count.times do
          if QualityReviewCaseSelector.select_case_for_quality_review?
            QualityReviewTask.create(assigned_to: create(:user), appeal: create(:appeal), created_at: Time.zone.now)
          end
        end
      end

      it "should hit at least the monthly minimum of QR tasks" do
        expect(QualityReviewTask.count).to be >= 130
      end
    end

    context "after reaching the monthly limit" do
      let!(:qr_tasks) do
        QualityReviewCaseSelector::MONTHLY_LIMIT_OF_QUAILITY_REVIEWS.times do
          QualityReviewTask.create(assigned_to: create(:user), appeal: create(:appeal), created_at: Time.zone.now)
        end
      end

      it "returns true" do
        expect(QualityReviewCaseSelector.reached_monthly_limit_in_quality_reviews?).to be(true)
      end
    end
  end
end
