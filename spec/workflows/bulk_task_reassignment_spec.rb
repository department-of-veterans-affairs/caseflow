# frozen_string_literal: true

describe BulkTaskReassignment, :all_dbs do
  before { allow_any_instance_of(Task).to receive(:automatically_assign_org_task?).and_return(false) }

  let(:user) { create(:user) }

  let(:task_count) { 4 }
  let(:parent_assignee) { create(:organization) }
  let(:parent_task_type) { :task }
  let(:parent_tasks) { create_list(parent_task_type, task_count, assigned_to: parent_assignee) }

  let(:task_type) { :task }
  let!(:tasks) do
    parent_tasks.map { |parent| create(task_type, assigned_to: user, parent: parent) }
  end

  let(:ids_output) { tasks.pluck(:id).sort.join(", ") }

  describe "#new" do
    subject { BulkTaskReassignment.new(user) }

    context "when the user does not exist" do
      let(:user) { nil }
      let(:tasks) { nil }

      it "throws an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#process" do
    subject { BulkTaskReassignment.new(user).process }

    context "there are no tasks to reassign" do
      before { tasks.each { |task| task.update!(assigned_to_id: user.id + 1) } }

      it "tells the caller that there are no tasks to reassign" do
        expected_output = "There aren't any open tasks assigned to this user."
        expect { subject }.to raise_error(BulkTaskReassignment::NoTasksToReassign).with_message(expected_output)
      end
    end

    context "there are tasks to reassign" do
      context "the tasks have no parents" do
        before { tasks.each { |task| task.update!(parent_id: nil) } }

        it "fails and warns the caller of tasks without open parents" do
          orphaned_ids_output = tasks.pluck(:id).sort.join(", ")
          expected_output = "Open tasks (#{orphaned_ids_output}) assigned to the user have no parent task"
          expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskParent).with_message(expected_output)
        end
      end

      context "the tasks have parents assigned to an organization with a different task type" do
        before do
          tasks.each { |task| task.update!(type: FoiaTask.name) }
          parent_tasks.map do |parent|
            create(:ama_judge_assign_task, assigned_to: user, parent: parent)
            create(:ama_judge_decision_review_task, assigned_to: user, parent: parent)
          end
        end

        it "fails and warns the caller of tasks that are not judge tasks" do
          bad_type_ids_output = tasks.map(&:id).sort.join(", ")
          expected_output = "Open tasks (#{bad_type_ids_output}) assigned to the user have parent task " \
                            "assigned to an organization but has a different task type"
          expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskParent).with_message(expected_output)
        end
      end

      context "the tasks have parents assigned to a user with the same task type" do
        before { parent_tasks.each { |parent| parent.update!(assigned_to: create(:user)) } }

        it "fails and warns the caller of parents assigned to a user with the same task type" do
          bad_type_ids_output = tasks.map(&:id).sort.join(", ")
          expected_output = "Open tasks (#{bad_type_ids_output}) assigned to the user have parent task " \
                            "assigned to a user but has the same type"
          expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskParent).with_message(expected_output)
        end
      end

      context "the tasks are JudgeAssignTasks" do
        let(:task_type) { :ama_judge_assign_task }

        context "with open children" do
          let(:child_tasks) { tasks.map { |task| create(:task, parent: task) } }

          it "fails and warns the caller of open children of JudgeAssignTasks" do
            bad_parent_output = child_tasks.map(&:id).sort.join(", ")
            expected_output = "JudgeAssignTasks have open children (#{bad_parent_output})"
            expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskParent).with_message(expected_output)
          end
        end

        context "with no children" do
          it "describes what changes will be made and makes them" do
            expect(Rails.logger).to receive(:info).exactly(9).times

            subject
            tasks.each do |task|
              expect(task.reload.cancelled?).to eq true
              expect(task.instructions).to include format(
                COPY::BULK_REASSIGN_INSTRUCTIONS, Constants.TASK_STATUSES.cancelled, user.css_id
              )
            end
            expect(DistributionTask.all.count).to eq task_count
          end
        end
      end

      context "the tasks are JudgeDecisionReviewTasks" do
        let(:task_type) { :ama_judge_decision_review_task }

        context "with no open children" do
          let(:child_tasks) { tasks.first(2).map { |task| create(:task, parent: task) } }
          let!(:child_atty_tasks) { tasks.last(2).map { |task| create(:ama_attorney_task, parent: task) } }

          it "fails and warns the caller of open children of JudgeAssignTasks" do
            bad_parent_output = child_tasks.map(&:parent_id).sort.join(", ")
            expected_output = "JudgeDecisionReviewTasks (#{bad_parent_output}) have no valid child attorney tasks"
            expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskParent).with_message(expected_output)
          end
        end

        context "with children attorney tasks (and assignee attorney is being made inactive)" do
          let(:attorney) { create(:user) }
          let!(:child_tasks) do
            tasks.map { |task| create(:ama_attorney_task, :completed, parent: task, assigned_to: attorney) }
          end

          context "but no judge team for the attorney" do
            it "fails and notifies user of attorney tasks with no new judge team" do
              bad_parent_output = child_tasks.map(&:id).join(", ")
              expected_output = "AttorneyTasks (#{bad_parent_output}) assignee does not belong to a judge team with " \
                                "an active judge"
              expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskAssignee).with_message(expected_output)
            end
          end

          context "but no different judge team for the attorney" do
            let!(:judge_team) { JudgeTeam.create_for_judge(user) }

            before { judge_team.add_user(attorney) }

            it "fails and notifies user of attorney tasks where the assignee is only in the inactive judge's team" do
              bad_parent_output = child_tasks.map(&:id).join(", ")
              expected_output = "AttorneyTasks (#{bad_parent_output}) assignee does not belong to a judge team with " \
                                "an active judge"
              expect { subject }.to raise_error(BulkTaskReassignment::InvalidTaskAssignee).with_message(expected_output)
            end
          end

          context "with a judge to be the new assignee for new parent JudgeDecisionReviewTasks" do
            let!(:judge_team) { JudgeTeam.create_for_judge(create(:user)) }

            before { judge_team.add_user(attorney) }

            it "cancels original parent JudgeDecisionReviewTasks and moves attorney tasks to new JDRT" do
              judge_review_message = "Cancelling #{task_count} JudgeDecisionReviewTasks with ids #{ids_output} and " \
                                      "moving #{task_count} AttorneyTasks to new JudgeDecisionReviewTasks assigned " \
                                      "to the attorney's new judge"
              expect(Rails.logger).to receive(:info).with(judge_review_message)

              subject
              tasks.each do |task|
                expect(task.reload.cancelled?).to eq true
                expect(task.instructions).to include format(
                  COPY::BULK_REASSIGN_INSTRUCTIONS, "reassigned", user.css_id
                )
              end
              expect(JudgeDecisionReviewTask.count).to eq task_count * 2
              expect(JudgeDecisionReviewTask.open.count).to eq task_count

              new_tasks = JudgeDecisionReviewTask.where(id: AttorneyTask.all.map(&:parent_id))
              expect(new_tasks.all? { |task| task.assigned_to == judge_team.judge }).to eq true
              expect(new_tasks.all? { |task| task.status == "on_hold" }).to eq true
              expect(new_tasks.all? { |task| task.children.length == 1 }).to eq true
            end
          end
        end
      end

      context "the tasks are AttorneyTasks" do
        let(:task_type) { :ama_attorney_task }
        let(:parent_task_type) { :ama_judge_decision_review_task }
        let(:parent_assignee) { create(:user) }

        it "describes what changes will be made and makes them" do
          parent_ids_output = parent_tasks.pluck(:id).sort.join(", ")
          judge_review_message = "Cancelling #{task_count} AttorneyTasks with ids #{ids_output}, " \
                                  "JudgeDecisionReviewTasks with ids #{parent_ids_output}, and creating " \
                                  "#{task_count} JudgeAssignTasks"
          expect(Rails.logger).to receive(:info).with(judge_review_message)

          subject
          tasks.each do |task|
            expect(task.reload.cancelled?).to eq true
            expect(task.instructions).to include format(
              COPY::BULK_REASSIGN_INSTRUCTIONS, Constants.TASK_STATUSES.cancelled, user.css_id
            )
          end
          parent_tasks.each do |task|
            expect(task.reload.cancelled?).to eq true
            expect(task.instructions).to include format(
              COPY::BULK_REASSIGN_INSTRUCTIONS, Constants.TASK_STATUSES.cancelled, user.css_id
            )
          end
          new_tasks = JudgeAssignTask.all
          new_tasks.each do |task|
            expect(task.instructions).to include format(
              COPY::BULK_REASSIGN_INSTRUCTIONS, Constants.TASK_STATUSES.assigned, user.css_id
            )
          end
          expect(new_tasks.count).to eq task_count
        end
      end

      context "the tasks have parent tasks assigned to an organization" do
        context "when the organization does not use automatic assignment of tasks" do
          it "describes what changes will be made and makes them" do
            manual_org_message = "Cancelling #{task_count} tasks with ids #{ids_output} and moving #{task_count} " \
                                  "parent tasks back to the organization's unassigned queue tab"
            expect(Rails.logger).to receive(:info).with(manual_org_message)

            subject
            tasks.each do |task|
              expect(task.reload.cancelled?).to eq true
              expect(task.instructions).to include format(
                COPY::BULK_REASSIGN_INSTRUCTIONS, Constants.TASK_STATUSES.cancelled, user.css_id
              )
            end
            parent_tasks.each { |task| expect(task.reload.assigned?).to eq true }
            expect(Task.open.count).to eq task_count
          end
        end

        context "when the organization uses automatic assignment of tasks" do
          let(:team_member_count) { task_count * 2 }
          let(:parent_assignee) { BvaDispatch.singleton }
          let(:parent_task_type) { :bva_dispatch_task }
          let(:task_type) { :bva_dispatch_task }

          before do
            team_member_count.times { |_| parent_assignee.add_user(create(:user)) }
          end

          context "when there are more organization members than tasks to reassign" do
            it "describes what changes will be made and makes them" do
              automatic_org_message = "Reassigning #{task_count} tasks with ids #{ids_output} to " \
                                      "#{team_member_count} members of the parent tasks' organization"
              expect(Rails.logger).to receive(:info).with(automatic_org_message)

              subject
              tasks.each do |task|
                expect(task.reload.cancelled?).to eq true
                expect(task.instructions).to include format(COPY::BULK_REASSIGN_INSTRUCTIONS, "reassigned", user.css_id)
              end
              parent_tasks.each { |task| expect(task.reload.on_hold?).to eq true }

              new_tasks = Task.open.where(assigned_to_type: User.name)
              new_tasks.each do |task|
                expect(task.instructions).to include format(COPY::BULK_REASSIGN_INSTRUCTIONS, "reassigned", user.css_id)
              end
              expect(new_tasks.map(&:parent_id)).to match_array parent_tasks.map(&:id)
              expect(new_tasks.distinct.pluck(:assigned_to_id).count).to eq task_count
            end
          end

          context "when there are fewer organization members than tasks to reassign" do
            let(:task_count) { 12 }
            let(:team_member_count) { task_count / 4 }

            it "describes what changes will be made and makes them" do
              automatic_org_message = "Reassigning #{task_count} tasks with ids #{ids_output} to " \
                                      "#{team_member_count} members of the parent tasks' organization"
              expect(Rails.logger).to receive(:info).with(automatic_org_message)

              subject
              tasks.each do |task|
                expect(task.reload.cancelled?).to eq true
                expect(task.instructions).to include format(COPY::BULK_REASSIGN_INSTRUCTIONS, "reassigned", user.css_id)
              end
              parent_tasks.each { |task| expect(task.reload.on_hold?).to eq true }

              new_tasks = Task.open.where(assigned_to_type: User.name)
              new_tasks.each do |task|
                expect(task.instructions).to include format(COPY::BULK_REASSIGN_INSTRUCTIONS, "reassigned", user.css_id)
              end
              expect(new_tasks.map(&:parent_id)).to match_array parent_tasks.map(&:id)
              expect(new_tasks.distinct.pluck(:assigned_to_id).count).to eq team_member_count
              expect(new_tasks.group(:assigned_to_id).count.values.all?(task_count / team_member_count)).to eq true
            end
          end
        end
      end

      context "the tasks have parent tasks assigned to a user" do
        let(:parent_assignee) { create(:user) }
        let(:task_type) { :foia_task }

        it "describes what changes will be made and makes them" do
          user_message = "Cancelling #{task_count} tasks with ids #{ids_output} and moving #{task_count} parent " \
                          "tasks back to the parent's assigned user's assigned tab"
          expect(Rails.logger).to receive(:info).with(user_message)

          subject
          tasks.each do |task|
            expect(task.reload.cancelled?).to eq true
            expect(task.instructions).to include format(
              COPY::BULK_REASSIGN_INSTRUCTIONS, Constants.TASK_STATUSES.cancelled, user.css_id
            )
          end
          parent_tasks.each { |task| expect(task.reload.assigned?).to eq true }
          expect(Task.open.count).to eq task_count
        end
      end
    end
  end

  describe "#perform_dry_run" do
    subject { BulkTaskReassignment.new(user).perform_dry_run }

    context "the tasks are JudgeAssignTasks" do
      let(:task_type) { :ama_judge_assign_task }

      it "only describes what changes will be made" do
        judge_assign_message = "Would cancel #{task_count} JudgeAssignTasks with ids #{ids_output} and create " \
                                "#{task_count} DistributionTasks"
        expect(Rails.logger).to receive(:info).with(judge_assign_message)

        subject
        tasks.each { |task| expect(task.reload.assigned?).to eq true }
        expect(DistributionTask.any?).to be_falsey
      end
    end

    context "the tasks are JudgeDecisionReviewTasks" do
      let(:task_type) { :ama_judge_decision_review_task }

      context "with children attorney tasks" do
        let(:attorney) { create(:user) }
        let!(:child_tasks) do
          tasks.map { |task| create(:ama_attorney_task, :completed, parent: task, assigned_to: attorney) }
        end
        let!(:judge_team) { JudgeTeam.create_for_judge(create(:user)) }

        before { judge_team.add_user(attorney) }

        it "only describes what changes will be made" do
          judge_review_message = "Would cancel #{task_count} JudgeDecisionReviewTasks with ids #{ids_output} " \
                                  "and move #{task_count} AttorneyTasks to new JudgeDecisionReviewTasks assigned" \
                                  " to the attorney's new judge"
          expect(Rails.logger).to receive(:info).with(judge_review_message)

          subject
          tasks.each { |task| expect(task.reload.on_hold?).to eq true }
          expect(child_tasks.map(&:parent_id)).to eq tasks.map(&:id)
          expect(JudgeDecisionReviewTask.count).to eq task_count
        end
      end
    end

    context "the tasks are AttorneyTasks" do
      let(:task_type) { :ama_attorney_task }
      let(:parent_task_type) { :ama_judge_decision_review_task }
      let(:parent_assignee) { create(:user) }

      it "only describes what changes will be made" do
        parent_ids_output = parent_tasks.pluck(:id).sort.join(", ")
        judge_review_message = "Would cancel #{task_count} AttorneyTasks with ids #{ids_output}, " \
                                "JudgeDecisionReviewTasks with ids #{parent_ids_output}, and create #{task_count} " \
                                "JudgeAssignTasks"
        expect(Rails.logger).to receive(:info).with(judge_review_message)

        subject
        tasks.each { |task| expect(task.reload.assigned?).to eq true }
        parent_tasks.each { |task| expect(task.reload.on_hold?).to eq true }
        expect(JudgeAssignTask.count).to eq 0
      end
    end

    context "the tasks have parent tasks assigned to an organization" do
      context "when the organization does not use automatic assignment of tasks" do
        it "only describes what changes will be made" do
          manual_org_message = "Would cancel #{task_count} tasks with ids #{ids_output} and move #{task_count} " \
                                "parent tasks back to the organization's unassigned queue tab"
          expect(Rails.logger).to receive(:info).with(manual_org_message)

          subject
          tasks.each { |task| expect(task.reload.assigned?).to eq true }
          expect(Task.open.count).to eq task_count * 2
          expect(tasks.map(&:parent_id)).to eq parent_tasks.map(&:id)
        end
      end

      context "when the organization uses automatic assignment of tasks" do
        let(:team_member_count) { task_count * 2 }
        let(:parent_assignee) { BvaDispatch.singleton }

        before do
          team_member_count.times { |_| parent_assignee.add_user(create(:user)) }
        end

        it "only describes what changes will be made" do
          automatic_org_message = "Would reassign #{task_count} tasks with ids #{ids_output} to " \
                                    "#{team_member_count} members of the parent tasks' organization"
          expect(Rails.logger).to receive(:info).with(automatic_org_message)

          subject
          tasks.each { |task| expect(task.reload.assigned?).to eq true }
          expect(Task.open.count).to eq task_count * 2
          expect(tasks.map(&:parent_id)).to eq parent_tasks.map(&:id)
        end
      end
    end

    context "the tasks have parent tasks assigned to a user" do
      let(:parent_assignee) { create(:user) }
      let(:task_type) { :foia_task }

      it "only describes what changes will be made" do
        user_message = "Would cancel #{task_count} tasks with ids #{ids_output} and move #{task_count} parent " \
                        "tasks back to the parent's assigned user's assigned tab"
        expect(Rails.logger).to receive(:info).with(user_message)

        subject
        tasks.each { |task| expect(task.reload.assigned?).to eq true }
        expect(Task.open.count).to eq task_count * 2
        expect(tasks.map(&:parent_id)).to eq parent_tasks.map(&:id)
      end
    end
  end
end
