# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"
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
          ids = from_task.all.pluck(:id)
          expected_output = <<~OUTPUT
            *** DRY RUN
            *** pass 'false' as the third argument to execute
            Would change #{count} #{from_task_name}s with ids #{ids.join(', ')} into #{to_task_name}s
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
          ids = from_task.all.pluck(:id)
          expected_output = <<~OUTPUT
            Changing #{count} #{from_task_name}s with ids #{ids.join(', ')} into #{to_task_name}s
            Revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect(Rails.logger).to receive(:info).with(
            "Changing #{task_count} #{from_task_name}s with ids #{ids.join(', ')} into #{to_task_name}s"
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
                Changing #{count} #{from_task_name}s with ids #{change_ids.join(', ')} into #{to_task_name}s
                Revert with: bundle exec rake tasks:change_type[#{to_task_name},#{from_task_name},#{change_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing #{subset_count} #{from_task_name}s with ids #{change_ids.join(', ')} into #{to_task_name}s"
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
              Would change #{count} #{from_task_name}s with ids #{change_ids.join(', ')} into #{to_task_name}s
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
            Would change assignee of #{count} #{target_task_name}s with ids #{ids.join(', ')} from #{from_org.name} to #{to_org.name}
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
            Changing assignee of #{count} #{target_task_name}s with ids #{ids.join(', ')} from #{from_org.name} to #{to_org.name}
            Revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{ids.join(',')}]
          OUTPUT
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect(Rails.logger).to receive(:info).with(
            "Changing assignee of #{count} #{target_task_name}s with ids #{ids.join(', ')} " \
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
                Changing assignee of #{count} #{target_task_name}s with ids #{change_ids.join(', ')} from #{from_org.name} to #{to_org.name}
                Revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{change_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing assignee of #{count} #{target_task_name}s with ids #{change_ids.join(', ')} " \
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
                Changing assignee of #{count} #{target_task_name}s with ids #{matching_ids.join(', ')} from #{from_org.name} to #{to_org.name}
                Revert with: bundle exec rake tasks:change_organization_assigned_to[#{target_task_name},#{to_org.id},#{from_org.id},false,#{matching_ids.join(',')}]
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect(Rails.logger).to receive(:info).with(
                "Changing assignee of #{count} #{target_task_name}s with ids #{matching_ids.join(', ')} " \
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
              Would change assignee of #{count} #{target_task_name}s with ids #{change_ids.join(', ')} from #{from_org.name} to #{to_org.name}
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

    let(:dry_run) { true }
    let(:args) { [user_id, dry_run] }

    subject do
      Rake::Task["tasks:reassign_from_user"].reenable
      Rake::Task["tasks:reassign_from_user"].invoke(*args)
    end

    context "the user id does not relate to a user" do
      let(:user_id) { 444 }

      it "fails to find the user" do
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "there are no tasks to reassign" do
      it "tells the caller that there are no tasks to reassign" do
        expected_output = "There aren't any open tasks assigned to this user."
        expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
        expect { subject }.to raise_error(NoTasksToReassign).with_message(expected_output)
      end
    end

    context "there are tasks to reassign" do
      before { allow_any_instance_of(Task).to receive(:automatically_assign_org_task?).and_return(false) }

      let(:task_count) { 4 }
      let(:parent_assignee) { create(:organization) }
      let(:parent_tasks) { create_list(:generic_task, task_count, :on_hold, assigned_to: parent_assignee) }

      let(:task_type) { :generic_task }
      let!(:tasks) do
        parent_tasks.map { |parent| create(task_type, assigned_to: user, parent: parent) }
      end


      context "the tasks have no parents" do
        before { tasks.each { |task| task.update!(parent_id: nil) } }

        it "fails and warns the caller of tasks without open parents" do
          orphaned_ids_output = tasks.map(&:id).reverse.join(", ")
          expected_output = "Open tasks (#{orphaned_ids_output}) assigned to User #{user_id} have no parent task"
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to raise_error(InvalidTaskParent).with_message(expected_output)
        end
      end

      context "the tasks have parents assigned to an organization with a different task type" do
        before do
          tasks.each { |task| task.update!(type: FoiaTask.name) }
          parent_tasks.map do |parent|
            create(:ama_judge_task, assigned_to: user, parent: parent)
            create(:ama_judge_decision_review_task, assigned_to: user, parent: parent)
          end
        end

        it "fails and warns the caller of tasks that are not judge tasks" do
          bad_type_ids_output = tasks.map(&:id).reverse.join(", ")
          expected_output = "Open tasks (#{bad_type_ids_output}) assigned to User #{user.id} have parent task " \
                            "assigned to an organization but has a different task type"
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to raise_error(InvalidTaskParent).with_message(expected_output)
        end
      end

      context "the tasks have parents assigned to a user with the same task type" do
        before { parent_tasks.each { |parent| parent.update!(assigned_to_type: User.name) } }

        it "fails and warns the caller of parents assigned to a user with the same task type" do
          bad_type_ids_output = tasks.map(&:id).reverse.join(", ")
          expected_output = "Open tasks (#{bad_type_ids_output}) assigned to User #{user.id} have parent task " \
                            "assigned to a user but has the same type"
          expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
          expect { subject }.to raise_error(InvalidTaskParent).with_message(expected_output)
        end
      end

      context "the tasks are JudgeAssignTasks" do
        let(:task_type) { :ama_judge_task }

        context "with open children" do
          let(:child_tasks) { tasks.map { |task| create(:task, parent_id: task.id) } }

          it "fails and warns the caller of open children of JudgeAssignTasks" do
            bad_parent_output = child_tasks.map(&:id).join(", ")
            expected_output = "JudgeAssignTasks have open children (#{bad_parent_output})"
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            expect { subject }.to raise_error(InvalidTaskParent).with_message(expected_output)
          end
        end

        context "with no children" do
          context "when on a dry run" do
            it "only describes what changes will be made" do
              count = task_count
              ids = tasks.pluck(:id).reverse
              expected_output = <<~OUTPUT
                *** DRY RUN
                *** pass 'false' as the third argument to execute
                Would cancel #{count} JudgeAssignTasks with ids #{ids.join(', ')} and create #{count} DistributionTasks
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              # TODO: fix
              # expect { subject }.to output(expected_output).to_stdout
              subject
              tasks.each { |task| expect(task.reload.assigned?).to eq true }
              expect(DistributionTask.any?).to be_falsey
            end
          end

          context "when executing" do
            let(:dry_run) { false }

            it "describes what changes will be made and makes them" do
              count = task_count
              ids = tasks.pluck(:id).reverse
              expected_output = <<~OUTPUT
                Cancelling #{count} JudgeAssignTasks with ids #{ids.join(', ')} and creating #{count} DistributionTasks
              OUTPUT
              # TODO: fix
              # expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              # expect(Rails.logger).to receive(:info).with(expected_output)
              # expect { subject }.to output(expected_output).to_stdout
              subject
              tasks.each { |task| expect(task.reload.cancelled?).to eq true }
              expect(DistributionTask.all.count).to eq count
            end
          end
        end
      end

      context "the tasks are JudgeDecisionReviewTasks" do
        let(:task_type) { :ama_judge_decision_review_task }

        context "with no open children" do
          let(:child_tasks) { tasks.first(2).map { |task| create(:task, parent_id: task.id) } }
          let!(:child_atty_tasks) { tasks.last(2).map { |task| create(:ama_attorney_task, parent_id: task.id) } }

          it "fails and warns the caller of open children of JudgeAssignTasks" do
            bad_parent_output = child_tasks.reverse.map(&:parent_id).join(", ")
            expected_output = "JudgeDecisionReviewTasks (#{bad_parent_output}) have no open child attorney tasks"
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            expect { subject }.to raise_error(InvalidTaskParent).with_message(expected_output)
          end
        end

        context "with open children attorney tasks" do
          let(:attorney) { create(:user) }
          let!(:child_tasks) do
            tasks.map { |task| create(:ama_attorney_task, parent_id: task.id, assigned_to: attorney) }
          end

          context "but no judge team for the attorney" do
            it "fails and notifies user of attorney tasks with no new judge team" do
              bad_parent_output = child_tasks.map(&:id).join(", ")
              expected_output = "AttorneyTasks (#{bad_parent_output}) assignee does not belong to a judge team with " \
                                "an active judge"
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect { subject }.to raise_error(InvalidTaskAssignee).with_message(expected_output)
            end
          end

          context "but no different judge team for the attorney" do
            let!(:judge_team) { JudgeTeam.create_for_judge(user) }

            before { OrganizationsUser.add_user_to_organization(attorney, judge_team) }

            it "fails and notifies user of attorney tasks where the assignee is only in the inactive judge's team" do
              bad_parent_output = child_tasks.map(&:id).join(", ")
              expected_output = "AttorneyTasks (#{bad_parent_output}) assignee does not belong to a judge team with " \
                                "an active judge"
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              expect { subject }.to raise_error(InvalidTaskAssignee).with_message(expected_output)
            end
          end

          context "with a new judge assignee" do
            let!(:judge_team) { JudgeTeam.create_for_judge(create(:user)) }

            before { OrganizationsUser.add_user_to_organization(attorney, judge_team) }

            context "when on a dry run" do
              it "only describes what changes will be made" do
                count = task_count
                ids = tasks.pluck(:id).reverse
                expected_output = <<~OUTPUT
                  *** DRY RUN
                  *** pass 'false' as the third argument to execute
                  Would cancel #{count} JudgeDecisionReviewTasks with ids #{ids.join(', ')} and and move
                  #{count} AttorneyTasks to new JudgeDecisionReviewTasks assigned to the attorney's new judge
                OUTPUT
                expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
                # TODO: fix
                # expect { subject }.to output(expected_output).to_stdout
                subject
                tasks.each { |task| expect(task.reload.on_hold?).to eq true }
                expect(child_tasks.map(&:parent_id)).to eq tasks.map(&:id)
                expect(JudgeDecisionReviewTask.count).to eq count
              end
            end

            context "when executing" do
              let(:dry_run) { false }

              it "describes what changes will be made and makes them" do
                count = task_count
                ids = tasks.pluck(:id).reverse
                expected_output = <<~OUTPUT
                  *** DRY RUN
                  *** pass 'false' as the third argument to execute
                  Would cancel #{count} JudgeDecisionReviewTasks with ids #{ids.join(', ')} and and move
                  #{count} AttorneyTasks to new JudgeDecisionReviewTasks assigned to the attorney's new judge
                OUTPUT
                # TODO: fix
                # expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
                # expect(Rails.logger).to receive(:info).with(expected_output)
                # expect { subject }.to output(expected_output).to_stdout
                subject
                tasks.each { |task| expect(task.reload.cancelled?).to eq true }
                expect(JudgeDecisionReviewTask.count).to eq count * 2
                expect(JudgeDecisionReviewTask.open.count).to eq count
                new_tasks = JudgeDecisionReviewTask.where(id: AttorneyTask.all.map(&:parent_id))
                expect(new_tasks.all? { |task| task.assigned_to == judge_team.judge }).to eq true
                expect(new_tasks.all? { |task| task.status == "on_hold" }).to eq true
                expect(new_tasks.all? { |task| task.children.length == 1 }).to eq true
              end
            end
          end
        end
      end

      context "the tasks have parent tasks assigned to an organization" do
        context "when the organization does not use automatic assignment of tasks" do
          context "when on a dry run" do
            it "only describes what changes will be made" do
              count = task_count
              ids = tasks.pluck(:id).reverse
              expected_output = <<~OUTPUT
                *** DRY RUN
                *** pass 'false' as the third argument to execute
                Would cancel #{count} tasks with ids #{ids.join(', ')} and move #{count} parent tasks back to the
                organization's unassigned queue tab
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              # TODO: fix
              # expect { subject }.to output(expected_output).to_stdout
              subject
              tasks.each { |task| expect(task.reload.assigned?).to eq true }
              expect(GenericTask.open.count).to eq count * 2
              expect(tasks.map(&:parent_id)).to eq parent_tasks.map(&:id)
            end
          end

          context "when executing" do
            let(:dry_run) { false }

            it "describes what changes will be made and makes them" do
              count = task_count
              ids = tasks.pluck(:id).reverse
              expected_output = <<~OUTPUT
                *** DRY RUN
                *** pass 'false' as the third argument to execute
                Cancelling #{count} tasks with ids #{ids.join(', ')} and moving #{count} parent tasks back to the
                organization's unassigned queue tab
              OUTPUT
              # TODO: fix
              # expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              # expect(Rails.logger).to receive(:info).with(expected_output)
              # expect { subject }.to output(expected_output).to_stdout
              subject
              tasks.each { |task| expect(task.reload.cancelled?).to eq true }
              parent_tasks.each { |task| expect(task.reload.assigned?).to eq true }
              expect(GenericTask.open.count).to eq count
            end
          end
        end

        context "when the organization uses automatic assignment of tasks" do
          let(:team_member_count) { task_count * 2 }
          let(:parent_assignee) { Colocated.singleton }

          before do
            team_member_count.times { |_| OrganizationsUser.add_user_to_organization(create(:user), parent_assignee) }
          end

          context "when on a dry run" do
            it "only describes what changes will be made" do
              count = task_count
              ids = tasks.pluck(:id).reverse
              expected_output = <<~OUTPUT
                *** DRY RUN
                *** pass 'false' as the third argument to execute
                Would reassign #{count} tasks with ids #{ids.join(', ')} to #{team_member_count} members of the
                #{parent_assignee.name} organization
              OUTPUT
              expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
              # TODO: fix
              # expect { subject }.to output(expected_output).to_stdout
              subject
              tasks.each { |task| expect(task.reload.assigned?).to eq true }
              expect(GenericTask.open.count).to eq count * 2
              expect(tasks.map(&:parent_id)).to eq parent_tasks.map(&:id)
            end
          end

          context "when executing" do
            let(:dry_run) { false }

            context "when there are more organization members than tasks to reassign" do
              it "describes what changes will be made and makes them" do
                count = task_count
                ids = tasks.pluck(:id).reverse
                expected_output = <<~OUTPUT
                  *** DRY RUN
                  *** pass 'false' as the third argument to execute
                  Reassigning #{count} tasks with ids #{ids.join(', ')} to #{team_member_count} members of the
                  #{parent_assignee.name} organization
                OUTPUT
                # TODO: fix
                # expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
                # expect(Rails.logger).to receive(:info).with(expected_output)
                # expect { subject }.to output(expected_output).to_stdout
                subject
                tasks.each { |task| expect(task.reload.cancelled?).to eq true }
                parent_tasks.each { |task| expect(task.reload.on_hold?).to eq true }
                new_tasks = GenericTask.open.where(assigned_to_type: User.name)
                new_tasks.each { |task| expect(task.reload.assigned?).to eq true }
                expect(new_tasks.map(&:parent_id)).to match_array parent_tasks.map(&:id)
                expect(new_tasks.distinct.pluck(:assigned_to_id).count).to eq count
              end
            end

            context "when there are fewer organization members than tasks to reassign" do
              let(:task_count) { 12 }
              let(:team_member_count) { task_count / 4 }

              it "describes what changes will be made and makes them" do
                count = task_count
                ids = tasks.pluck(:id).reverse
                expected_output = <<~OUTPUT
                  *** DRY RUN
                  *** pass 'false' as the third argument to execute
                  Reassigning #{count} tasks with ids #{ids.join(', ')} to #{team_member_count} members of the
                  #{parent_assignee.name} organization
                OUTPUT
                # TODO: fix
                # expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
                # expect(Rails.logger).to receive(:info).with(expected_output)
                # expect { subject }.to output(expected_output).to_stdout
                subject
                tasks.each { |task| expect(task.reload.cancelled?).to eq true }
                parent_tasks.each { |task| expect(task.reload.on_hold?).to eq true }
                new_tasks = GenericTask.open.where(assigned_to_type: User.name)
                new_tasks.each { |task| expect(task.reload.assigned?).to eq true }
                expect(new_tasks.map(&:parent_id)).to match_array parent_tasks.map(&:id)
                expect(new_tasks.distinct.pluck(:assigned_to_id).count).to eq team_member_count
                expect(new_tasks.group(:assigned_to_id).count.values.all?(task_count / team_member_count)).to eq true
              end
            end
          end
        end
      end

      context "the tasks have parent tasks assigned to a user" do
        let(:parent_assignee) { create(:user) }
        let(:task_type) { :task }

        context "when on a dry run" do
          it "only describes what changes will be made" do
            count = task_count
            ids = tasks.pluck(:id).reverse
            expected_output = <<~OUTPUT
              *** DRY RUN
              *** pass 'false' as the third argument to execute
              Would cancel #{count} tasks with ids #{ids.join(', ')} and move #{count} parent tasks back to the
              parent's assigned user's assigned tab
            OUTPUT
            expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            # TODO: fix
            # expect { subject }.to output(expected_output).to_stdout
            subject
            tasks.each { |task| expect(task.reload.assigned?).to eq true }
            expect(Task.open.count).to eq count * 2
            expect(tasks.map(&:parent_id)).to eq parent_tasks.map(&:id)
          end
        end

        context "when executing" do
          let(:dry_run) { false }

          it "describes what changes will be made and makes them" do
            count = task_count
            ids = tasks.pluck(:id).reverse
            expected_output = <<~OUTPUT
              *** DRY RUN
              *** pass 'false' as the third argument to execute
              Would cancel #{count} tasks with ids #{ids.join(', ')} and move #{count} parent tasks back to the
              parent's assigned user's assigned tab
            OUTPUT
            # TODO: fix
            # expect(Rails.logger).to receive(:info).with("Invoked with: #{args.join(', ')}")
            # expect(Rails.logger).to receive(:info).with(expected_output)
            # expect { subject }.to output(expected_output).to_stdout
            subject
            tasks.each { |task| expect(task.reload.cancelled?).to eq true }
            parent_tasks.each { |task| expect(task.reload.assigned?).to eq true }
            expect(Task.open.count).to eq count
          end
        end
      end
    end
  end
end
