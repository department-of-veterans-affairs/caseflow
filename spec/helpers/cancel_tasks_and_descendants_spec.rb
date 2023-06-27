# frozen_string_literal: true

require "helpers/cancel_tasks_and_descendants"

describe CancelTasksAndDescendants do
  describe ".call" do
    context "when task_relation is not given" do
      subject(:call) { described_class.call }

      it "assignes RequestStore[:current_user]" do
        expect { call }.to change { RequestStore[:current_user] }.
          from(nil).to(User.system_user)
      end

      it "does not cancel any tasks" do
        expect_any_instance_of(Task).not_to receive(:cancel_task_and_child_subtasks)
        call
      end

      it { is_expected.to be_nil }
    end

    context "when task_relation is given " do
      subject(:call) { described_class.call(task_relation) }

      let(:task_relation) { instance_double("ActiveRecord::Relation") }
      let(:task_1) { instance_double("Task", cancel_task_and_child_subtasks: nil) }
      let(:task_2) { instance_double("Task", cancel_task_and_child_subtasks: nil) }
      let(:task_3) { instance_double("Task", cancel_task_and_child_subtasks: nil) }

      before do
        expect(task_relation).to receive(:find_each).
          and_yield(task_1).
          and_yield(task_2).
          and_yield(task_3)
      end

      it "cancels each task and its descendants" do
        aggregate_failures do
          expect(task_1).to receive(:cancel_task_and_child_subtasks)
          expect(task_2).to receive(:cancel_task_and_child_subtasks)
          expect(task_3).to receive(:cancel_task_and_child_subtasks)
        end
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
      end
    end
  end
end
