# frozen_string_literal: true

describe QualityReviewCaseSelector, :all_dbs do
  describe ".reached_monthly_limit_in_quality_reviews?" do
    subject { QualityReviewCaseSelector.reached_monthly_limit_in_quality_reviews? }
    context "when a realistic number of cases are completed" do
      # Originally pulled from prod with:
      # Task.where(
      #   appeal_type: Appeal.name,
      #   assigned_to_type: Organization.name,
      #   type: [QualityReviewTask.name, BvaDispatchTask.name],
      #   created_at: 2.month.ago.beginning_of_month..2.month.ago.end_of_month
      # ).count
      # Updated to use the constants provided in the file with margin to not be a seemingly arbitrary number.
      # As of 4/2024, there were over 4000 cases being completed each month.
      let(:complete_cases_count) do
        limit = QualityReviewCaseSelector::MONTHLY_LIMIT_OF_QUALITY_REVIEWS
        probability = QualityReviewCaseSelector::QUALITY_REVIEW_SELECTION_PROBABILITY

        ((limit / probability) * 1.2).to_i
      end

      it "should hit at least the monthly minimum of QR tasks" do
        count = 0
        complete_cases_count.times { count += 1 if QualityReviewCaseSelector.select_case_for_quality_review? }

        expect(count).to be >= QualityReviewCaseSelector::MONTHLY_LIMIT_OF_QUALITY_REVIEWS
      end
    end

    context "after reaching the monthly limit" do
      before { stub_const("QualityReviewCaseSelector::MONTHLY_LIMIT_OF_QUALITY_REVIEWS", 5) }

      let!(:qr_tasks) { create_list(:qr_task, QualityReviewCaseSelector::MONTHLY_LIMIT_OF_QUALITY_REVIEWS) }

      it "returns true" do
        expect(subject).to be(true)
      end

      context "some tasks are cancelled" do
        before { qr_tasks.last.update_columns(status: Constants.TASK_STATUSES.cancelled) }

        it "returns true" do
          expect(subject).to be(true)
        end
      end

      context "but some tasks are assigned to users" do
        before { qr_tasks.last.update!(assigned_to: create(:user)) }

        it "returns false" do
          expect(subject).to be(false)
        end
      end
    end
  end
end
