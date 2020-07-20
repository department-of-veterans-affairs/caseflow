# frozen_string_literal: true

describe "fixes", :all_dbs do
  include_context "rake"

  describe "fixes:activate_stalled_hearing_tasks" do
    subject do
      Rake::Task["fixes:activate_stalled_hearing_tasks"].reenable
      Rake::Task["fixes:activate_stalled_hearing_tasks"].invoke(*args)
    end

    context "there are appeals with stalled hearing tasks" do
      # a legacy appeal
      let(:appeal1) { create(:legacy_appeal, vacols_case: create(:case)) }
      let(:root_task1) { create(:root_task, appeal: appeal1) }
      let(:hearing_task1) { create(:hearing_task, parent: root_task1) }
      let!(:schedule_hearing_task1) { create(:schedule_hearing_task, parent: hearing_task1) }
      # a second legacy appeal
      let(:appeal2) { create(:legacy_appeal, vacols_case: create(:case)) }
      let(:root_task2) { create(:root_task, appeal: appeal2) }
      let(:hearing_task2) { create(:hearing_task, parent: root_task2) }
      let!(:schedule_hearing_task2) { create(:schedule_hearing_task, parent: hearing_task2) }
      # an ama appeal
      let(:appeal3) { create(:appeal) }
      let(:root_task3) { create(:root_task, appeal: appeal3) }
      let(:distribution_task3) { create(:distribution_task, parent: root_task3) }
      let(:hearing_task3) { create(:hearing_task, parent: distribution_task3) }
      let!(:schedule_hearing_task3) { create(:schedule_hearing_task, parent: hearing_task3) }
      let!(:track_veteran_task3) { create(:track_veteran_task, parent: root_task3) }

      let(:schedule_hearing_tasks) { [schedule_hearing_task1, schedule_hearing_task2, schedule_hearing_task3] }

      before do
        schedule_hearing_task1.update_columns(status: Constants.TASK_STATUSES.on_hold)
        schedule_hearing_task2.update_columns(status: Constants.TASK_STATUSES.on_hold)
        schedule_hearing_task3.update_columns(status: Constants.TASK_STATUSES.on_hold)
      end

      context "no dry run or limit variables are passed" do
        let(:args) { [] }

        it "only describes what changes will be made" do
          ids = HearingTask.all.map(&:id).sort
          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the second argument to execute
            Found 3 stalled HearingTasks. Would update 3 stalled HearingTasks with IDs #{ids}!
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to output(expected_output).to_stdout
          # no changes have been made
          schedule_hearing_tasks.each do |task|
            expect(task.reload.status).to eq Constants.TASK_STATUSES.on_hold
          end
        end
      end

      context "hearing task ids are passed" do
        let(:args) { [0, hearing_task1.id, hearing_task3.id] }

        it "only describes what changes will be made" do
          ids = [hearing_task1.id, hearing_task3.id]
          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the second argument to execute
            Found 2 stalled HearingTasks. Would update 2 stalled HearingTasks with IDs #{ids}!
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to output(expected_output).to_stdout
          # no changes have been made
          schedule_hearing_tasks.each do |task|
            expect(task.reload.status).to eq Constants.TASK_STATUSES.on_hold
          end
        end
      end

      context "dry run is set to false" do
        context "limit is set to zero" do
          let(:args) { [0, "false"] }

          it "makes the requested changes" do
            ids = HearingTask.all.map(&:id).sort
            expected_output = <<~OUTPUT
              Found 3 stalled HearingTasks. Updating 3 stalled HearingTasks with IDs #{ids}!
            OUTPUT
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            expect(Rails.logger).to receive(:info).with expected_output.chomp
            expect { subject }.to output(expected_output).to_stdout
            # changes have been made
            schedule_hearing_tasks.each do |task|
              expect(task.reload.status).to eq Constants.TASK_STATUSES.assigned
            end
          end

          context "hearing task ids are passed" do
            let(:args) { [0, "false", hearing_task2.id, hearing_task3.id] }

            it "makes the requested changes" do
              ids = [hearing_task2.id, hearing_task3.id]
              expected_output = <<~OUTPUT
                Found 2 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids}!
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with expected_output.chomp
              expect { subject }.to output(expected_output).to_stdout
              # only the second and third tasks have been changed
              expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.on_hold
              expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.assigned
            end

            context "one of the passed ids is for a non-matching hearing task" do
              let(:args) { [0, "false", hearing_task2.id, hearing_task3.id] }

              before do
                schedule_hearing_task3.update_columns(status: Constants.TASK_STATUSES.cancelled)
                hearing_task3.update_columns(status: Constants.TASK_STATUSES.cancelled)
              end

              it "doesn't try to change the un-open HearingTask" do
                ids = [hearing_task2.id]
                expected_output = <<~OUTPUT
                  Found 1 stalled HearingTasks. Updating 1 stalled HearingTasks with IDs #{ids}!
                OUTPUT
                expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
                expect(Rails.logger).to receive(:info).with expected_output.chomp
                expect { subject }.to output(expected_output).to_stdout
                # only the second task has been changed
                expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.on_hold
                expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.assigned
                expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.cancelled
              end
            end
          end

          context "a hearing task isn't open" do
            before do
              schedule_hearing_task1.update_columns(status: Constants.TASK_STATUSES.cancelled)
              hearing_task1.update_columns(status: Constants.TASK_STATUSES.cancelled)
            end

            it "doesn't try to change the un-open HearingTask" do
              ids = HearingTask.open.map(&:id).sort
              expected_output = <<~OUTPUT
                Found 2 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids}!
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with expected_output.chomp
              expect { subject }.to output(expected_output).to_stdout
              # only the second and third tasks have been changed
              expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.cancelled
              expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.assigned
            end
          end

          context "there's another HearingTask on the same appeal as one of the stalled HearingTasks" do
            let(:hearing_task2b) { create(:hearing_task, parent: root_task2) }
            let!(:schedule_hearing_task2b) { create(:schedule_hearing_task, parent: hearing_task2b) }

            it "doesn't try to change the open HearingTask on the same appeal" do
              ids = [hearing_task1.id, hearing_task3.id]
              expected_output = <<~OUTPUT
                Found 2 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids}!
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with expected_output.chomp
              expect { subject }.to output(expected_output).to_stdout
              # only the first and third tasks have been changed
              expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.on_hold
              expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.assigned
            end
          end

          context "a HearingTask has an active descendant" do
            before do
              schedule_hearing_task3.update_columns(status: Constants.TASK_STATUSES.in_progress)
            end

            it "doesn't try to change the open HearingTask with the active descendant" do
              ids = [hearing_task1.id, hearing_task2.id]
              expected_output = <<~OUTPUT
                Found 2 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids}!
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with expected_output.chomp
              expect { subject }.to output(expected_output).to_stdout
              # only the first and second tasks have been changed
              expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.in_progress
            end
          end

          context "a HearingTask has more than one child" do
            let!(:disposition_task1) do
              create(:assign_hearing_disposition_task, parent: hearing_task1)
            end

            before do
              disposition_task1.update_columns(status: Constants.TASK_STATUSES.cancelled)
            end

            it "doesn't try to change the open HearingTask with the active descendant" do
              ids = [hearing_task2.id, hearing_task3.id]
              expected_output = <<~OUTPUT
                Found 2 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids}!
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with expected_output.chomp
              expect { subject }.to output(expected_output).to_stdout
              # only the second and third tasks have been changed
              expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.on_hold
              expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.assigned
            end
          end

          context "a HearingTask's on_hold ScheduleHearingTask child has an open descendant" do
            let!(:verify_address_task2) do
              create(:hearing_admin_action_verify_address_task, parent: schedule_hearing_task2)
            end

            before do
              verify_address_task2.update_columns(status: Constants.TASK_STATUSES.on_hold)
            end

            it "doesn't try to change the open HearingTask with the open descendant" do
              ids = [hearing_task1.id, hearing_task3.id]
              expected_output = <<~OUTPUT
                Found 2 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids}!
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with expected_output.chomp
              expect { subject }.to output(expected_output).to_stdout
              # only the first and third tasks have been changed
              expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.assigned
              expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.on_hold
              expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.assigned
            end
          end
        end

        context "limit is set to a positive integer" do
          let(:args) { [2, "false"] }

          it "makes the requested changes" do
            ids = HearingTask.all.map(&:id).sort
            expected_output = <<~OUTPUT
              Found 3 stalled HearingTasks. Updating 2 stalled HearingTasks with IDs #{ids[0..1]}!
            OUTPUT
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            expect(Rails.logger).to receive(:info).with expected_output.chomp
            expect { subject }.to output(expected_output).to_stdout
            # only the first two tasks have been changed
            expect(schedule_hearing_task1.reload.status).to eq Constants.TASK_STATUSES.assigned
            expect(schedule_hearing_task2.reload.status).to eq Constants.TASK_STATUSES.assigned
            expect(schedule_hearing_task3.reload.status).to eq Constants.TASK_STATUSES.on_hold
          end
        end
      end
    end

    context "there are no stalled hearing tasks" do
      let(:args) { [0, "false"] }

      it "tells the caller that there are no tasks to change" do
        expected_output = "No stalled HearingTasks were found."
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(NoStalledHearingTasksFound).with_message(expected_output)
      end
    end
  end
end
