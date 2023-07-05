# frozen_string_literal: true

require "helpers/cancel_tasks_and_descendants"

describe CancelTasksAndDescendants do
  describe ".call" do
    context "when task_relation is not given" do
      subject(:call) { described_class.call }

      it "assigns RequestStore[:current_user]" do
        expect { call }.to change { RequestStore[:current_user] }.
          from(nil).to(User.system_user)
      end

      it "logs all the things" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)

        expect(rails_logger).to receive(:info)
          .with(/Elapsed time \(sec\):/).ordered

        call
      end

      it { is_expected.to eq(true) }
    end

    context "when task_relation is given " do
      subject(:call) { described_class.call(task_relation) }

      let(:task_relation) { Task.where(id: [task_1, task_2, task_3]) }
      let(:task_1) { create(:veteran_record_request_task) }
      let(:task_2) { create(:veteran_record_request_task) }
      let(:task_3) { create(:veteran_record_request_task) }

      before do
        expect(task_relation).to receive(:find_each).at_least(:once)
          .and_yield(task_1)
          .and_yield(task_2)
          .and_yield(task_3)
      end

      it "cancels each task and its descendants" do
        aggregate_failures do
          expect(task_1).to receive(:cancel_task_and_child_subtasks)
          expect(task_2).to receive(:cancel_task_and_child_subtasks)
          expect(task_3).to receive(:cancel_task_and_child_subtasks)
        end
        call
      end

      it "logs all the things" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)

        expect(rails_logger).to receive(:info)
          .with(/Elapsed time \(sec\):/).ordered

        call
      end

      context "when a task fails to cancel" do
        before do
          expect(task_2).to receive(:cancel_task_and_child_subtasks).
            and_raise(ActiveModel::ValidationError.new(Task.new))
        end

        it "does not prevent cancellation of other tasks in the relation" do
          aggregate_failures do
            expect(task_1).to receive(:cancel_task_and_child_subtasks)
            expect(task_3).to receive(:cancel_task_and_child_subtasks)
          end
          call
        end

        it "does not raise error" do
          expect { call }.not_to raise_error
        end

        it "logs all the things" do
          rails_logger = Rails.logger
          allow(Rails).to receive(:logger).and_return(rails_logger)

          expect(rails_logger).to receive(:info)
            .with(/Elapsed time \(sec\):/).ordered

          call
        end

        it { is_expected.to eq(true) }
      end
    end
  end
end
