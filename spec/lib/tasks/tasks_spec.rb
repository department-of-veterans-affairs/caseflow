# frozen_string_literal: true

require "rake"

describe "task rake tasks", :postgres do
  before :all do
    Rake.application = Rake::Application.new
    Rake.application.rake_require "tasks/tasks"
    Rake::Task.define_task :environment
  end

  describe "tasks:change_type" do
    let(:from_task) { ScheduleHearingTask }
    let(:from_task_name) { from_task.name }
    let(:to_task) { AssignHearingDispositionTask }
    let(:to_task_name) { to_task.name }

    subject do
      Rake::Task["tasks:change_type"].reenable
      Rake::Task["tasks:change_type"].invoke(*args)
    end

    context "there are tasks to change" do
      let(:task_count) { 10 }
      let(:subset_count) { 6 }
      let!(:hold_hearing_tasks) { create_list(:schedule_hearing_task, task_count) }

      context "no dry run variable is passed" do
        let(:args) { [from_task_name, to_task_name] }

        it "only describes what changes will be made" do
          count = from_task.count
          ids = from_task.all.pluck(:id).sort
          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the third argument to execute
            Would change #{count} #{from_task_name}s with ids #{ids.join(',')} into #{to_task_name}s
            Would revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to output(expected_output).to_stdout
          expect(from_task.count).to eq task_count
          expect(from_task.all.pluck(:id)).to match_array ids
          expect(to_task.any?).to be_falsey
        end
      end

      context "dry run is set to false" do
        let(:args) { [from_task_name, to_task_name, "false"] }

        it "makes the requested changes" do
          count = from_task.count
          ids = from_task.all.pluck(:id).sort
          expected_output = <<~OUTPUT
            Changing #{count} #{from_task_name}s with ids #{ids.join(',')} into #{to_task_name}s
            Revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect(Rails.logger).to receive(:info).with(
            "Changing #{task_count} #{from_task_name}s with ids #{ids.join(',')} into #{to_task_name}s"
          )
          expect { subject }.to output(expected_output).to_stdout
          expect(to_task.count).to eq task_count
          expect(to_task.all.pluck(:id)).to match_array ids
          expect(from_task.any?).to be_falsey
        end
      end

      context "id numbers are passed" do
        context "dry run is set to false" do
          let(:args) { [from_task_name, to_task_name, "false", *change_ids] }
          let(:change_ids) { [] }

          context "all the id numbers match existing tasks" do
            let(:change_ids) { hold_hearing_tasks.pluck(:id)[0..subset_count - 1] }

            it "makes the requested changes" do
              count = change_ids.count
              expected_output = <<~OUTPUT
                Changing #{count} #{from_task_name}s with ids #{change_ids.join(',')} into #{to_task_name}s
                Revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{change_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing #{subset_count} #{from_task_name}s with ids #{change_ids.join(',')} into #{to_task_name}s"
              )
              expect { subject }.to output(expected_output).to_stdout
              expect(to_task.count).to eq count
              expect(to_task.all.pluck(:id)).to match_array change_ids
              expect(from_task.count).to eq task_count - subset_count
            end
          end

          context "some of the id numbers do not match existing tasks" do
            let!(:other_task) { create(:ama_judge_decision_review_task) }
            let(:change_ids) { hold_hearing_tasks.pluck(:id)[0..subset_count - 1] + [other_task.id] }

            it "raises an error" do
              message_pattern = /Couldn't find all #{from_task_name}s with 'id'/
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect { subject }.to raise_error(ActiveRecord::RecordNotFound).with_message(message_pattern)
            end
          end
        end

        context "no dry run variable is passed" do
          let(:args) { [from_task_name, to_task_name, *change_ids] }
          let(:change_ids) { hold_hearing_tasks.pluck(:id)[0..subset_count - 1] }

          it "correctly describes what changes will be made" do
            count = change_ids.count
            joined = change_ids.join(",")
            expected_output = <<~OUTPUT
              *** DRY RUN
              *** pass 'false' as the third argument to execute
              Would change #{count} #{from_task_name}s with ids #{change_ids.sort.join(',')} into #{to_task_name}s
              Would revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{joined}]
            OUTPUT
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            expect { subject }.to output(expected_output).to_stdout
            expect(from_task.count).to eq task_count
            expect(to_task.any?).to be_falsey
          end
        end
      end
    end

    context "there are no tasks to change" do
      let(:hold_hearing_tasks) { [] }
      let(:args) { [from_task_name, to_task_name, "false"] }

      it "tells the caller that there are no tasks to change" do
        expected_output = "There aren't any #{from_task_name}s available to change."
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(NoTasksToChange).with_message(expected_output)
      end
    end

    context "a non task class is passed" do
      let(:from_task) { JudgeTeam }
      let(:args) { [from_task_name, to_task_name, false] }

      it "warns about passing a class that's not a task" do
        expected_output = "#{from_task_name} is not a valid Task type!"
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(InvalidTaskType).with_message(expected_output)
      end
    end
  end

  describe "tasks:change_organization_assigned_to" do
    let(:target_task) { ScheduleHearingTask }
    let(:target_task_name) { target_task.name }
    let(:target_task_factory) { :schedule_hearing_task }
    let(:from_org) { HearingsManagement.singleton }
    let(:to_org) { Bva.singleton }
    let(:task_count) { 10 }

    subject do
      Rake::Task["tasks:change_organization_assigned_to"].reenable
      Rake::Task["tasks:change_organization_assigned_to"].invoke(*args)
    end

    context "there are tasks to change" do
      let(:subset_count) { 6 }
      let!(:target_tasks) { create_list(target_task_factory, task_count, assigned_to: from_org) }

      context "no dry run variable is passed" do
        let(:args) { [target_task_name, from_org.id, to_org.id] }

        it "only describes what changes will be made" do
          count = target_task.count
          ids = target_task.all.pluck(:id).sort
          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the fourth argument to execute
            Would change assignee of #{count} #{target_task_name}s with ids #{ids.join(',')} from #{from_org.name} to #{to_org.name}
            Would revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to output(expected_output).to_stdout
          expect(target_task.all.pluck(:assigned_to_id).uniq).to match_array [from_org.id]
        end
      end

      context "dry run is set to false" do
        let(:args) { [target_task_name, from_org.id, to_org.id, "false"] }

        it "makes the requested changes" do
          count = target_task.count
          ids = target_task.all.pluck(:id).sort
          expected_output = <<~OUTPUT
            Changing assignee of #{count} #{target_task_name}s with ids #{ids.join(',')} from #{from_org.name} to #{to_org.name}
            Revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect(Rails.logger).to receive(:info).with(
            "Changing assignee of #{count} #{target_task_name}s with ids #{ids.join(',')} " \
            "from #{from_org.name} to #{to_org.name}"
          )
          expect { subject }.to output(expected_output).to_stdout
          expect(target_task.all.pluck(:assigned_to_id).uniq).to match_array [to_org.id]
        end
      end

      context "id numbers are passed" do
        context "dry run is set to false" do
          let(:args) { [target_task_name, from_org.id, to_org.id, "false", *change_ids] }
          let(:change_ids) { [] }

          context "all the id numbers match existing tasks" do
            let(:change_ids) { target_tasks.pluck(:id)[0..subset_count - 1] }

            it "makes the requested changes" do
              count = change_ids.count
              expected_output = <<~OUTPUT
                Changing assignee of #{count} #{target_task_name}s with ids #{change_ids.sort.join(',')} from #{from_org.name} to #{to_org.name}
                Revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{change_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing assignee of #{count} #{target_task_name}s with ids #{change_ids.join(',')} " \
                "from #{from_org.name} to #{to_org.name}"
              )

              expect { subject }.to output(expected_output).to_stdout

              changed_tasks = target_task.find(change_ids)
              expect(changed_tasks.count).to eq change_ids.count

              all_ids = target_tasks.pluck(:id)
              expect(target_task.where(id: all_ids, assigned_to: to_org).count).to eq subset_count
              expect(target_task.where(id: all_ids, assigned_to: from_org).count).to eq task_count - subset_count
            end
          end

          context "some of the id numbers do not match existing tasks" do
            let!(:other_task) { create(:ama_judge_decision_review_task) }
            let(:matching_ids) { target_tasks.pluck(:id)[0..subset_count - 1] }
            let(:change_ids) { matching_ids + [other_task.id] }

            it "only changes the appropriate tasks" do
              count = matching_ids.count
              expected_output = <<~OUTPUT
                Changing assignee of #{count} #{target_task_name}s with ids #{matching_ids.sort.join(',')} from #{from_org.name} to #{to_org.name}
                Revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{matching_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing assignee of #{count} #{target_task_name}s with ids #{matching_ids.join(',')} " \
                "from #{from_org.name} to #{to_org.name}"
              )

              expect { subject }.to output(expected_output).to_stdout
            end
          end
        end

        context "no dry run variable is passed" do
          let(:args) { [target_task_name, from_org.id, to_org.id, *change_ids] }
          let(:change_ids) { target_tasks.pluck(:id)[0..subset_count - 1] }

          it "correctly describes what changes will be made" do
            count = change_ids.count
            expected_output = <<~OUTPUT
              *** DRY RUN
              *** pass 'false' as the fourth argument to execute
              Would change assignee of #{count} #{target_task_name}s with ids #{change_ids.sort.join(',')} from #{from_org.name} to #{to_org.name}
              Would revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{change_ids.join(',')}]
            OUTPUT
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")

            expect { subject }.to output(expected_output).to_stdout

            all_ids = target_tasks.pluck(:id)
            expect(target_task.where(id: all_ids, assigned_to: from_org).count).to eq task_count
            expect(target_task.where(id: all_ids, assigned_to: to_org).count).to eq 0
          end
        end
      end
    end

    context "there are no tasks to change" do
      let!(:target_tasks) { create_list(target_task_factory, task_count, assigned_to: to_org) }
      let(:args) { [target_task_name, from_org.id, to_org.id, "false"] }

      it "tells the caller that there are no tasks to change" do
        expected_output = "There aren't any #{target_task_name}s assigned to #{from_org.name} available to change."
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(NoTasksToChange).with_message(expected_output)
      end
    end

    context "a non task class is passed" do
      let(:target_task) { JudgeTeam }
      let(:args) { [target_task_name, from_org.id, to_org.id, "false"] }

      it "warns about passing a class that's not a task" do
        expected_output = "#{target_task_name} is not a valid Task type!"
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(InvalidTaskType).with_message(expected_output)
      end
    end

    context "an id that doesn't belong to an organization is passed" do
      let(:bad_org_id) { 123_456 }
      let(:args) { [target_task_name, bad_org_id, to_org.id, "false"] }

      it "warns about passing an id that doesn't belong to an organization" do
        expected_output = "No organization with id #{bad_org_id}!"
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(InvalidOrganization).with_message(expected_output)
      end
    end
  end

  describe "tasks:reassign_from_user" do
    let(:user) { create(:user) }
    let(:user_id) { user.id }

    let(:args) { [user_id] }

    subject do
      Rake::Task["tasks:reassign_from_user"].reenable
      Rake::Task["tasks:reassign_from_user"].invoke(*args)
    end

    context "the user id does not relate to a user" do
      let(:user_id) { 444 }

      it "fails to find the user" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when on a dry run" do
      it "tells the user how to execute" do
        expected_output = <<~OUTPUT
          *** DRY RUN
          *** pass 'false' as the second argument to execute
        OUTPUT
        allow_any_instance_of(BulkTaskReassignment).to receive(:perform_dry_run).and_return(nil)
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to output(expected_output).to_stdout
      end
    end
  end
end
