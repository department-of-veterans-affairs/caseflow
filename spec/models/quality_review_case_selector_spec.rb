# frozen_string_literal: true

describe QualityReviewCaseSelector, :all_dbs do
  describe ".reached_monthly_limit_in_quality_reviews?" do
    subject { QualityReviewCaseSelector.reached_monthly_limit_in_quality_reviews? }
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
          create(:qr_task) if QualityReviewCaseSelector.select_case_for_quality_review?
        end
      end

      it "should hit at least the monthly minimum of QR tasks" do
        expect(QualityReviewTask.count).to be >= 130
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
