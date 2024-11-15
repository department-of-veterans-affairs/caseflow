# frozen_string_literal: true

require "helpers/cancel_tasks_and_descendants"
require "securerandom"

describe CancelTasksAndDescendants do
  describe ".call" do
    context "when task_relation is not given" do
      subject(:call) { described_class.call }

      it "assigns RequestStore[:current_user]" do
        expect { call }.to change { RequestStore[:current_user] }
          .from(nil).to(User.system_user)
      end

      it "appends appropriate logs to application logs" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)

        aggregate_failures do
          expect(rails_logger).to receive(:info)
            .with("Total tasks for cancellation: 0").ordered

          expect(rails_logger).not_to receive(:info)
            .with(/Task ids \[.+\] cancelled successfully/)

          expect(rails_logger).to receive(:info)
            .with(/Tasks cancelled successfully: 0/).ordered

          expect(rails_logger).to receive(:info)
            .with(/Elapsed time \(sec\):/).ordered
        end

        call
      end

      it "appends appropriate logs to stdout" do
        allow(SecureRandom).to receive(:uuid) { "dummy-request-id" }

        # rubocop:disable Layout/FirstArgumentIndentation
        expect { call }.to output(
          match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Total tasks for cancellation: 0"
          )).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Tasks cancelled successfully: 0"
          ))).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Elapsed time (sec):"
          )))
        ).to_stdout
        # rubocop:enable Layout/FirstArgumentIndentation
      end

      it { is_expected.to be_nil }
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

        allow(task_1).to receive(:self_and_descendants) { [task_1] }
        allow(task_2).to receive(:self_and_descendants) { [task_2] }
        allow(task_3).to receive(:self_and_descendants) { [task_3] }
      end

      it "cancels each task and its descendants" do
        aggregate_failures do
          expect(task_1).to receive(:cancel_task_and_child_subtasks)
          expect(task_2).to receive(:cancel_task_and_child_subtasks)
          expect(task_3).to receive(:cancel_task_and_child_subtasks)
        end
        call
      end

      it "sets PaperTrail versions data appropriately for cancelled tasks" do
        request_id = SecureRandom.uuid
        allow(SecureRandom).to receive(:uuid) { request_id }

        call

        task_1_version = task_1.versions.last
        expect(task_1_version.whodunnit).to eq(User.system_user.id.to_s)
        expect(task_1_version.request_id).to eq(request_id)
      end

      it "appends appropriate logs to application logs" do
        rails_logger = Rails.logger
        allow(Rails).to receive(:logger).and_return(rails_logger)

        aggregate_failures do
          expect(rails_logger).to receive(:info)
            .with("Total tasks for cancellation: 3").ordered

          expect(rails_logger).to receive(:info)
            .with(/Task ids \[#{task_1.id}\] cancelled successfully/).ordered

          expect(rails_logger).to receive(:info)
            .with(/Task ids \[#{task_2.id}\] cancelled successfully/).ordered

          expect(rails_logger).to receive(:info)
            .with(/Task ids \[#{task_3.id}\] cancelled successfully/).ordered

          expect(rails_logger).to receive(:info)
            .with(/Tasks cancelled successfully: 3/).ordered

          expect(rails_logger).to receive(:info)
            .with(/Elapsed time \(sec\):/).ordered
        end

        call
      end

      it "appends appropriate logs to stdout" do
        allow(SecureRandom).to receive(:uuid) { "dummy-request-id" }

        # rubocop:disable Layout/FirstArgumentIndentation
        expect { call }.to output(
          match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Total tasks for cancellation: 3"
          )).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Task ids [#{task_1.id}] cancelled successfully"
          ))).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Task ids [#{task_2.id}] cancelled successfully"
          ))).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Task ids [#{task_3.id}] cancelled successfully"
          ))).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Tasks cancelled successfully: 3"
          ))).and(match(Regexp.escape(
            "[CancelTasksAndDescendants] [dummy-request-id] Elapsed time (sec):"
          )))
        ).to_stdout
        # rubocop:enable Layout/FirstArgumentIndentation
      end

      context "when a task fails to cancel" do
        before do
          expect(task_2).to receive(:cancel_task_and_child_subtasks)
            .and_raise(ActiveModel::ValidationError.new(Task.new))
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

        it "appends appropriate logs to application logs" do
          rails_logger = Rails.logger
          allow(Rails).to receive(:logger).and_return(rails_logger)

          aggregate_failures do
            expect(rails_logger).to receive(:info)
              .with("Total tasks for cancellation: 3").ordered

            expect(rails_logger).to receive(:info)
              .with(/Task ids \[#{task_1.id}\] cancelled successfully/).ordered

            expect(rails_logger).to receive(:error).with(
              /Task ids \[#{task_2.id}\] not cancelled due to error - Validation failed/
            ).ordered

            expect(rails_logger).to receive(:info)
              .with(/Task ids \[#{task_3.id}\] cancelled successfully/).ordered

            expect(rails_logger).to receive(:info)
              .with(/Tasks cancelled successfully: 2/).ordered

            expect(rails_logger).to receive(:info)
              .with(/Elapsed time \(sec\):/).ordered
          end

          call
        end

        it "appends appropriate logs to stdout" do
          allow(SecureRandom).to receive(:uuid) { "dummy-request-id" }

          # rubocop:disable Layout/FirstArgumentIndentation
          expect { call }.to output(
            match(Regexp.escape(
              "[CancelTasksAndDescendants] [dummy-request-id] Total tasks for cancellation: 3"
            )).and(match(Regexp.escape(
              "[CancelTasksAndDescendants] [dummy-request-id] Task ids [#{task_1.id}] cancelled successfully"
            ))).and(match(Regexp.escape(
              "[CancelTasksAndDescendants] [dummy-request-id] Task ids [#{task_2.id}] not cancelled due to error - " \
              "Validation failed"
            ))).and(match(Regexp.escape(
              "[CancelTasksAndDescendants] [dummy-request-id] Task ids [#{task_3.id}] cancelled successfully"
            ))).and(match(Regexp.escape(
              "[CancelTasksAndDescendants] [dummy-request-id] Tasks cancelled successfully: 2"
            ))).and(match(Regexp.escape(
              "[CancelTasksAndDescendants] [dummy-request-id] Elapsed time (sec):"
            )))
          ).to_stdout
          # rubocop:enable Layout/FirstArgumentIndentation
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
