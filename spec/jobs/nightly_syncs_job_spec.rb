# frozen_string_literal: true

describe NightlySyncsJob, :all_dbs do
  context "when the job runs successfully" do
    before do
      5.times { create(:staff) }

      @emitted_gauges = []
      allow(DataDogService).to receive(:emit_gauge) do |args|
        @emitted_gauges.push(args)
      end
    end

    subject { described_class.perform_now }

    it "updates cached_user_attributes table" do
      subject

      expect(CachedUser.count).to eq(5)
    end

    it "updates DataDog" do
      subject

      expect(@emitted_gauges).to include(
        app_name: "caseflow_job",
        metric_group: "nightly_syncs_job",
        metric_name: "runtime",
        metric_value: anything
      )
    end

    context "dangling LegacyAppeal" do
      context "with zero tasks" do
        let!(:legacy_appeal) { create(:legacy_appeal) }

        it "deletes the legacy appeal" do
          subject

          expect { legacy_appeal.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with open tasks" do
        let!(:legacy_appeal) { create(:legacy_appeal, :with_judge_assign_task) }

        it "cancels all open tasks and leaves the legacy appeal intact" do
          subject

          expect(legacy_appeal.reload).to_not be_nil
          expect(legacy_appeal.reload.tasks.open).to be_empty
        end
      end
    end

    context "open DecisionReviewTasks" do
      let(:education) { create(:business_line, url: "education") }
      let(:veteran) { create(:veteran) }
      let(:hlr) do
        create(:higher_level_review, benefit_type: "education", veteran_file_number: veteran.file_number)
      end
      let!(:request_issue) { create(:request_issue, :removed, decision_review: hlr) }
      let!(:task) { create(:higher_level_review_task, appeal: hlr, assigned_to: education) }
      let!(:board_grant_effectuation_task) do
        create(:board_grant_effectuation_task, appeal: hlr, assigned_to: education)
      end

      it "cancels any for completed cases" do
        expect(task.reload).to be_assigned

        subject

        expect(task.reload).to be_cancelled
        expect(board_grant_effectuation_task.reload).to be_assigned
      end
    end
  end
end
