# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe Task, :postgres do
  describe ".available_actions" do
    let(:task) { nil }
    let(:user) { nil }
    subject { task.available_actions(user) }

    context "when task is assigned to user" do
      let(:task) { create(:generic_task) }
      let(:user) { task.assigned_to }
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
          Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      it "should return team assign, person reassign, complete, and cancel actions" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to somebody else" do
      let(:task) { create(:generic_task) }
      let(:user) { create(:user) }
      let(:expected_actions) { [] }
      it "should return an empty array" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to an organization the user is a member of" do
      let(:org) { Organization.find(create(:organization).id) }
      let(:task) { create(:generic_task, assigned_to: org) }
      let(:user) { create(:user) }
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
          Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      before { allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true) }
      it "should return team assign, person assign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end
  end

  describe ".available_hearing_user_actions" do
    let!(:task) { create(:generic_task) }
    let(:user) { create(:user) }

    subject { task.available_hearing_user_actions(user) }

    it "returns no actions when task doesn't have an active hearing task ancestor" do
      expect(subject).to eq []
    end

    context "task has an active hearing task ancestor" do
      let(:appeal) { create(:appeal) }
      let!(:hearing_task) { create(:hearing_task, appeal: appeal) }
      let(:disposition_task_type) { :assign_hearing_disposition_task }
      let(:trait) { :assigned }
      let!(:disposition_task) do
        create(
          disposition_task_type,
          trait,
          parent: hearing_task,
          appeal: appeal
        )
      end
      let!(:task) { create(:no_show_hearing_task, parent: disposition_task, appeal: appeal) }

      context "user is a member of hearings management" do
        before do
          HearingsManagement.singleton.add_user(user)
        end

        it "returns no actions when user is not a member of hearing admin" do
          expect(subject).to eq []
        end
      end

      context "user is member of hearing admin" do
        before do
          HearingAdmin.singleton.add_user(user)
        end

        it "returns a create change hearing disposition task action" do
          expect(subject).to eq [Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h]
        end
      end

      context "hearing task has an inactive child disposition task" do
        let(:trait) { :cancelled }

        it "returns no actions" do
          expect(subject).to eq []
        end
      end

      context "hearing task has only an active child change hearing disposition task" do
        let(:disposition_task_type) { :change_hearing_disposition_task }

        it "returns no actions" do
          expect(subject).to eq []
        end
      end
    end

    context "task's appeal has an inactive hearing task associated with a hearing with a disposition" do
      let!(:appeal) { create(:appeal) }
      let!(:past_hearing_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
      let!(:hearing) do
        create(:hearing, appeal: appeal, disposition: past_hearing_disposition)
      end
      let!(:hearing_task) do
        create(:hearing_task, :completed, appeal: appeal)
      end
      let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
      let!(:hearing_task_2) { create(:hearing_task, appeal: appeal) }
      let!(:association_2) do
        create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
      end

      context "user is a member of hearings management and task is a ScheduleHearingTask" do
        let!(:task) { create(:schedule_hearing_task, parent: hearing_task_2, appeal: appeal) }

        before do
          HearingsManagement.singleton.add_user(user)
        end

        it "returns a create change previous hearing disposition task action" do
          expect(subject).to eq [Constants.TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK.to_h]
        end

        context "past hearing disposition is nil" do
          let!(:past_hearing_disposition) { nil }

          it "returns no actions" do
            expect(subject).to eq []
          end
        end

        context "task is not a ScheduleHearingTask" do
          let!(:task) { create(:assign_hearing_disposition_task, parent: hearing_task_2, appeal: appeal) }

          it "returns no actions" do
            expect(subject).to eq []
          end
        end
      end

      context "user is a member of hearing admin" do
        before do
          HearingAdmin.singleton.add_user(user)
        end

        it "returns no actions" do
          expect(subject).to eq []
        end
      end
    end
  end

  describe ".available_actions_unwrapper" do
    let(:user) { create(:user) }
    let(:task) { create(:generic_task, trait, assigned_to: assignee) }
    subject { task.available_actions_unwrapper(user) }

    context "when task assigned to the user is has been completed" do
      let(:assignee) { user }
      let(:trait) { :completed }
      let(:expected_actions) { [] }
      it "should return an empty list" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task assigned to an organization the user is a member of is on hold" do
      let(:assignee) { Organization.find(create(:organization).id) }
      let(:trait) { :on_hold }
      let(:expected_actions) { [] }
      before { allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true) }
      it "should return an empty list" do
        expect(subject).to eq(expected_actions)
      end
    end
  end

  describe ".verify_user_can_update!" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:org) { create(:organization) }
    let(:other_org) { create(:organization) }
    let(:task) { create(:generic_task, :in_progress, assigned_to: assignee) }

    before do
      org.add_user(user)
    end

    context "task assignee is current user" do
      let(:assignee) { user }
      it "should not raise an error" do
        expect { task.verify_user_can_update!(user) }.to_not raise_error
      end
    end

    context "task assignee is organization to which current user belongs" do
      let(:assignee) { org }
      it "should not raise an error" do
        expect { task.verify_user_can_update!(user) }.to_not raise_error
      end
    end

    context "task assignee is a different person" do
      let(:assignee) { other_user }
      it "should raise an error" do
        expect { task.verify_user_can_update!(user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end

    context "task assignee is organization to which current user does not belong" do
      let(:assignee) { other_org }
      it "should raise an error" do
        expect { task.verify_user_can_update!(user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end
  end

  describe ".update_from_params" do
    let(:user) { create(:user) }
    let(:org) { create(:organization) }
    let(:task) { create(:generic_task, :in_progress, assigned_to: assignee) }

    context "task is assigned to an organization" do
      let(:assignee) { org }

      context "and current user does not belong to that organization" do
        it "should raise an error when trying to update task" do
          expect do
            task.update_from_params({ status: Constants.TASK_STATUSES.completed }, user)
          end.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "and current user belongs to that organization" do
        before do
          org.add_user(user)
        end

        it "should update the task's status" do
          expect_any_instance_of(Task).to receive(:update!)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed }, user)
        end
      end
    end

    context "task is assigned to a person" do
      let(:other_user) { create(:user) }
      let(:assignee) { user }

      context "who is not the current user" do
        it "should raise an error when trying to update task" do
          expect { task.update_from_params({}, other_user) }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "who is the current user" do
        it "should receive the update" do
          expect_any_instance_of(Task).to receive(:update!)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed }, user)
        end

        it "should update the task's status" do
          expect(task.status).to eq(Constants.TASK_STATUSES.in_progress)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed }, user)
          expect(task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "and the parameters include a reassign parameter" do
        it "should call Task.reassign" do
          allow_any_instance_of(Task).to receive(:reassign).and_return(true)
          expect_any_instance_of(Task).to receive(:reassign)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed, reassign: { instructions: nil } }, user)
        end
      end
    end
  end

  describe ".create_many_from_params" do
    let(:parent_assignee) { create(:user) }
    let(:current_user) { create(:user) }
    let(:assignee) { create(:user) }
    let(:parent) { create(:generic_task, :in_progress, assigned_to: parent_assignee) }

    let(:good_params) do
      {
        status: Constants.TASK_STATUSES.completed,
        parent_id: parent.id,
        assigned_to_type: assignee.class.name,
        assigned_to_id: assignee.id
      }
    end
    let(:good_params_array) { [good_params] }

    context "when missing assignee parameter" do
      let(:params) do
        [{
          status: good_params[:status],
          parent_id: good_params[:parent_id],
          assigned_to_id: good_params[:assigned_to_id]
        }]
      end
      it "should raise error before not creating child task nor update status" do
        expect { Task.create_many_from_params(params, parent_assignee).first }.to raise_error(TypeError)
      end
    end

    context "when missing parent_id parameter" do
      let(:params) do
        [{
          status: good_params[:status],
          assigned_to_type: good_params[:assigned_to_type],
          assigned_to_id: good_params[:assigned_to_id]
        }]
      end
      it "should raise error before not creating child task nor update status" do
        expect { Task.create_many_from_params(params, parent_assignee).first }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when missing status parameter" do
      let(:params) do
        [{
          parent_id: good_params[:parent_id],
          assigned_to_type: good_params[:assigned_to_type],
          assigned_to_id: good_params[:assigned_to_id]
        }]
      end
      it "should create child task and not update parent task's status" do
        status_before = parent.status
        Task.create_many_from_params(params, parent_assignee)
        expect(Task.where(params.first).count).to eq(1)
        expect(parent.status).to eq(status_before)
      end
    end

    context "when parent task is assigned to a user" do
      context "when there is no current user" do
        it "should raise error and not create the child task nor update status" do
          expect { Task.create_many_from_params(good_params_array, nil).first }.to(
            raise_error(Caseflow::Error::ActionForbiddenError)
          )
        end
      end

      context "when the currently logged-in user owns the parent task" do
        let(:parent_assignee) { current_user }
        it "should create child task assigned by currently logged-in user" do
          child = Task.create_many_from_params(good_params_array, current_user).first
          expect(child.assigned_by_id).to eq(current_user.id)
        end
      end
    end

    context "when parent task is assigned to an organization" do
      let(:org) { create(:organization) }
      let(:parent) { create(:generic_task, :in_progress, assigned_to: org) }

      context "when there is no current user" do
        it "should raise error and not create the child task nor update status" do
          expect { Task.create_many_from_params(good_params_array, nil).first }.to(
            raise_error(Caseflow::Error::ActionForbiddenError)
          )
        end
      end

      context "when there is a currently logged-in user" do
        before do
          org.add_user(current_user)
        end
        it "should create child task assigned by currently logged-in user" do
          child = Task.create_many_from_params(good_params_array, current_user).first
          expect(child.assigned_by_id).to eq(current_user.id)
        end
      end
    end
  end

  describe ".reassign" do
    let(:org) { Organization.find(create(:organization).id) }
    let(:root_task) { RootTask.find(create(:root_task).id) }
    let(:org_task) { create(:generic_task, parent_id: root_task.id, assigned_to: org) }
    let(:task) { create(:generic_task, parent_id: org_task.id) }
    let(:old_assignee) { task.assigned_to }
    let(:new_assignee) { create(:user) }
    let(:params) do
      {
        assigned_to_id: new_assignee.id,
        assigned_to_type: new_assignee.class.name,
        instructions: "some instructions here"
      }
    end

    before { allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true) }

    subject { task.reassign(params, old_assignee) }

    context "When old assignee reassigns task with no child tasks to a new user" do
      it "reassign method should return list with old and new tasks" do
        expect(subject).to match_array(task.parent.children)
        expect(task.parent.children.length).to eq(2)
      end

      it "should change status of old task to completed but not complete parent task" do
        expect { subject }.to_not raise_error
        expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(task.parent.status).to_not eq(Constants.TASK_STATUSES.cancelled)
      end
    end

    context "When old assignee reassigns task with several child tasks to a new user" do
      let(:completed_children_cnt) { 4 }
      let!(:completed_children) do
        create_list(
          :generic_task,
          completed_children_cnt,
          :completed,
          parent_id: task.id
        )
      end
      let(:incomplete_children_cnt) { 5 }
      let!(:incomplete_children) { create_list(:generic_task, incomplete_children_cnt, parent_id: task.id) }

      before { task.on_hold! }

      it "reassign method should return list with old and new tasks and incomplete child tasks" do
        expect(subject.length).to eq(2 + incomplete_children_cnt)
      end

      it "incomplete children tasks are adopted by new task and completed tasks are not" do
        expect { subject }.to_not raise_error
        expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)

        new_task = task.parent.children.open.first
        expect(new_task.children.length).to eq(incomplete_children_cnt)
        expect(new_task.status).to eq(Constants.TASK_STATUSES.on_hold)

        task.reload
        expect(task.children.length).to eq(completed_children_cnt)
      end

      context "when the children are task timers" do
        let(:incomplete_children_cnt) { 1 }
        let!(:incomplete_children) { create_list(:timed_hold_task, incomplete_children_cnt, parent_id: task.id) }

        it "children timer tasks are adopted by new task and not cancelled" do
          expect { subject }.to_not raise_error
          expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)

          new_task = task.parent.children.open.first
          expect(new_task.children.length).to eq(incomplete_children_cnt)
          expect(new_task.children.all?(&:assigned?)).to eq(true)
          expect(new_task.status).to eq(Constants.TASK_STATUSES.on_hold)

          task.reload
          expect(task.children.length).to eq(completed_children_cnt)
        end
      end
    end
  end

  describe ".verify_org_task_unique" do
    context "when attempting to create two tasks for different appeals assigned to the same organization" do
      let(:organization) { create(:organization) }
      let(:appeals) { create_list(:appeal, 2) }
      let(:root_task) { create(:root_task) }
      let(:root_task_2) { create(:root_task) }
      let(:root_task_3) { create(:root_task) }

      before do
        BvaDispatch.singleton.add_user(create(:user))
        BvaDispatchTask.create_from_root_task(root_task)
        QualityReviewTask.create_from_root_task(root_task_3).update!(status: "completed")
      end

      it "should succeed" do
        expect do
          appeals.each do |a|
            root_task = RootTask.create(appeal: a)
            Task.create!(
              assigned_to: organization,
              parent_id: root_task.id,
              type: Task.name,
              appeal: a
            )
          end
        end.to_not raise_error
      end

      it "should not fail when the parent tasks are different" do
        # not specifying the error due to warning from capybara about false positives
        expect { BvaDispatchTask.create_from_root_task(root_task_2) }.to_not raise_error
      end

      it "should not fail when the duplicate task is completed" do
        expect do
          QualityReviewTask.create_from_root_task(root_task_3)
        end.to_not raise_error
      end

      it "should fail when organization-level BvaDispatchTask already exists with the same parent" do
        expect { BvaDispatchTask.create_from_root_task(root_task) }.to raise_error(Caseflow::Error::DuplicateOrgTask)
      end
    end
  end
end
