# frozen_string_literal: true

describe Task, :all_dbs do
  context "includes PrintsTaskTree concern" do
    describe ".structure" do
      let(:root_task) { create(:root_task) }
      let!(:bva_task) { create(:bva_dispatch_task, :in_progress, parent: root_task) }
      let(:judge_task) { create(:ama_judge_task, :completed, parent: root_task) }
      let!(:attorney_task) { create(:ama_attorney_task, :completed, parent: judge_task) }

      subject { root_task.structure(:id, :status) }

      it "outputs the task structure" do
        root_key = "#{root_task.type} #{root_task.id}, #{root_task.status}".to_sym
        judge_key = "#{judge_task.type} #{judge_task.id}, #{judge_task.status}".to_sym
        bva_key = "#{bva_task.type} #{bva_task.id}, #{bva_task.status}".to_sym
        attorney_key = "#{attorney_task.type} #{attorney_task.id}, #{attorney_task.status}".to_sym

        expect(subject.key?(root_key)).to be_truthy
        expect(subject[root_key].count).to eq 2
        judge_task_found = false
        bva_task_found = false
        subject[root_key].each do |child_task|
          if child_task.key? judge_key
            judge_task_found = true
            expect(child_task[judge_key].count).to eq 1
            expect(child_task[judge_key].first.key?(attorney_key)).to be_truthy
            expect(child_task[judge_key].first[attorney_key]).to eq []
          elsif child_task.key? bva_key
            bva_task_found = true
          end
        end
        expect(judge_task_found).to be_truthy
        expect(bva_task_found).to be_truthy
      end
    end
  end

  describe ".post_dispatch_task?" do
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }

    subject { ama_task.post_dispatch_task? }

    context "dispatch task is not complete" do
      let!(:bva_task) { create(:bva_dispatch_task, :in_progress, parent: root_task, appeal: appeal) }
      let(:ama_task) { create(:ama_task, parent: root_task, appeal: appeal) }

      it { is_expected.to be_falsey }
    end

    context "dispatch task is complete" do
      let!(:bva_task) { create(:bva_dispatch_task, :completed, parent: root_task, appeal: appeal) }

      context "sibling task created before dispatch task completed" do
        let(:ama_task) { create(:ama_task, created_at: bva_task.closed_at - 1, parent: root_task, appeal: appeal) }

        it { is_expected.to be_falsey }
      end

      context "sibling task created after dispatch task completed" do
        let(:ama_task) { create(:ama_task, created_at: bva_task.closed_at + 1, parent: root_task, appeal: appeal) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe ".when_child_task_completed" do
    let(:task) { create(:task, type: Task.name) }
    let(:child_status) { :assigned }
    let!(:child) { create(:task, child_status, type: Task.name, parent: task) }

    subject { task.reload.when_child_task_completed(child) }

    context "when on_hold task is assigned to a person" do
      context "when task has no child tasks" do
        let(:child) { nil }

        it "should not change the task's status" do
          status_before = task.status
          subject
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 incomplete child task" do
        let!(:child_status) { :in_progress }

        it "should not change the task's status" do
          status_before = task.status
          subject
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 complete child task" do
        let!(:child_status) { :completed }

        it "should change task's status to assigned" do
          status_before = task.status
          subject
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end

      context "when task is already closed" do
        let!(:child_status) { :completed }

        before { task.update!(status: Constants.TASK_STATUSES.completed) }

        it "does not change the status of the task" do
          subject
          expect(task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        let!(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }

        it "should not change the task's status" do
          status_before = task.status
          subject
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has only complete child tasks" do
        let(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }
        let!(:child) { completed_children.last }

        it "should change task's status to assigned" do
          status_before = task.reload.status
          subject
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end
    end

    context "when on_hold task is assigned to an organization" do
      let(:organization) { Organization.create!(name: "Other organization", url: "other") }
      let(:task) { create(:task, type: Task.name, assigned_to: organization) }

      context "when task has no child tasks" do
        let(:child) { nil }

        it "should not update any attribute of the task" do
          task_status = task.status
          subject
          expect(task.reload.status).to eq task_status
        end
      end

      context "when task has 1 incomplete child task" do
        let(:child_status) { :in_progress }

        it "should not update any attribute of the task" do
          task_status = task.status
          subject
          expect(task.reload.status).to eq task_status
        end
      end

      context "when task has 1 complete child task" do
        let(:child_status) { :completed }

        it "should update the task" do
          subject
          expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        end
      end

      context "when task is already closed" do
        let(:child_status) { :completed }

        before { task.update!(status: Constants.TASK_STATUSES.completed) }

        it "does not change the status of the task" do
          subject
          expect(task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        let!(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }

        it "should not update any attribute of the task" do
          task_status = task.status
          subject
          expect(task.reload.status).to eq task_status
        end
      end

      context "when task has only complete child tasks" do
        let(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }
        let!(:child) { completed_children.last }

        it "should update the task" do
          subject
          expect(task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when child task has a different type than parent" do
        let!(:child) { create(:quality_review_task, :completed, parent_id: task.id) }

        it "sets the status of the parent to assigned" do
          subject
          expect(task.reload.status).to eq(Constants.TASK_STATUSES.assigned)
        end
      end
    end
  end

  describe "#can_be_updated_by_user?" do
    subject { task.can_be_updated_by_user?(user) }

    context "when user is an assignee" do
      let(:user) { create(:user) }
      let(:task) { create(:ama_task, assigned_to: user) }

      it { is_expected.to be_truthy }
    end

    context "when user does not have access" do
      let(:user) { create(:user) }
      let(:task) { create(:ama_task, assigned_to: create(:user)) }

      it { is_expected.to be(false) }
    end
  end

  describe "#prepared_by_display_name" do
    let(:task) { create(:task, type: Task.name) }

    context "when there is no attorney_case_review" do
      it "should return nil" do
        expect(task.prepared_by_display_name).to eq(nil)
      end
    end

    context "when there is an attorney_case_review" do
      let!(:child) { create(:task, type: Task.name, appeal: task.appeal, parent_id: task.id) }
      let!(:attorney_case_reviews) do
        create(:attorney_case_review, task_id: child.id, attorney: create(:user, full_name: "Bob Smith"))
      end

      it "should return the most recent attorney case review" do
        expect(task.prepared_by_display_name).to eq(%w[Bob Smith])
      end
    end
  end

  describe "#duplicate_org_task" do
    let(:root_task) { create(:root_task) }
    let(:qr_user) { create(:user) }
    let!(:quality_review_organization_task) do
      create(:qr_task, assigned_to: QualityReview.singleton, parent: root_task)
    end
    let!(:quality_review_task) do
      create(:qr_task, assigned_to: qr_user, parent: quality_review_organization_task)
    end

    context "when there are duplicate organization tasks" do
      it "returns true when there is a duplicate task assigned to an organization" do
        expect(quality_review_organization_task.duplicate_org_task).to eq(true)
      end

      it "returns false otherwise" do
        expect(quality_review_task.duplicate_org_task).to eq(false)
      end
    end
  end

  describe "#latest_attorney_case_review" do
    let(:task) { create(:task, type: Task.name) }

    context "when there is no sub task" do
      it "should return nil" do
        expect(task.latest_attorney_case_review).to eq(nil)
      end
    end

    context "when there is a sub task" do
      let!(:child) { create(:task, type: Task.name, appeal: task.appeal, parent_id: task.id) }
      let!(:attorney_case_reviews) do
        [
          create(:attorney_case_review, task_id: child.id, created_at: 1.day.ago),
          create(:attorney_case_review, task_id: child.id, created_at: 2.days.ago)
        ]
      end

      it "should return the most recent attorney case review" do
        expect(task.latest_attorney_case_review).to eq(attorney_case_reviews.first)
      end
    end
  end

  describe "#cancel_task_and_child_subtasks" do
    let(:appeal) { create(:appeal) }
    let!(:top_level_task) { create(:task, appeal: appeal) }
    let!(:second_level_tasks) { create_list(:task, 2, appeal: appeal, parent: top_level_task) }
    let!(:third_level_task) { create_list(:task, 2, appeal: appeal, parent: second_level_tasks.first) }

    it "cancels all tasks and child subtasks" do
      initial_versions = second_level_tasks[0].versions.count

      top_level_task.reload.cancel_task_and_child_subtasks

      expect(second_level_tasks[0].versions.count).to eq(initial_versions + 2)
      expect(second_level_tasks[0].versions.last.object).to include("cancelled")

      [top_level_task, *second_level_tasks, *third_level_task].each do |task|
        expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      end
    end
  end

  describe ".root_task" do
    context "when sub-sub-sub...task has a root task" do
      let(:root_task) { create(:root_task) }
      let(:task) do
        t = create(:ama_task, parent_id: root_task.id)
        5.times { t = create(:ama_task, parent_id: t.id) }
        Task.last
      end

      it "should return the root_task" do
        expect(task.root_task.id).to eq(root_task.id)
      end
    end

    context "when sub-sub-sub...task does not have a root task" do
      let(:task) do
        t = create(:ama_task)
        5.times { t = create(:ama_task, parent_id: t.id) }
        Task.last
      end

      it "should throw an error" do
        expect { task.root_task }.to(raise_error) do |e|
          expect(e).to be_a(Caseflow::Error::NoRootTask)
          expect(e.message).to eq("Could not find root task for task with ID #{task.id}")
        end
      end
    end

    context "task is root task" do
      let(:task) { create(:root_task) }
      it "should return itself" do
        expect(task.root_task.id).to eq(task.id)
      end
    end
  end

  describe ".descendants" do
    let(:parent_task) { create(:ama_task) }

    subject { parent_task.reload.descendants }

    context "when a task has some descendants" do
      let(:children_count) { 6 }
      let(:grandkids_per_child) { 4 }
      let(:children) { create_list(:ama_task, children_count, parent: parent_task) }

      before { children.each { |t| create_list(:ama_task, grandkids_per_child, parent: t) } }

      it "returns a list of all descendants and itself" do
        total_grandkid_count = children_count * grandkids_per_child
        total_descendant_count = 1 + children_count + total_grandkid_count
        expect(subject.length).to eq(total_descendant_count)
      end
    end

    context "when a task has no descendants" do
      it "returns only itself" do
        expect(subject.length).to eq(1)
      end
    end
  end

  describe ".available_actions" do
    let(:task) { nil }
    let(:user) { nil }
    subject { task.available_actions(user) }

    context "when task is assigned to user" do
      let(:task) { create(:ama_task) }
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
      let(:task) { create(:ama_task) }
      let(:user) { create(:user) }
      let(:expected_actions) { [] }
      it "should return an empty array" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to an organization the user is a member of" do
      let(:org) { Organization.find(create(:organization).id) }
      let(:task) { create(:ama_task, assigned_to: org) }
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

  describe ".available_actions_unwrapper" do
    let(:user) { create(:user) }
    let(:task) { create(:ama_task, assigned_to: user) }

    subject { task.available_actions_unwrapper(user) }

    context "when task assigned to the user is has been completed" do
      let(:assignee) { user }
      let(:expected_actions) { [] }

      before do
        task.update!(status: :completed)
      end

      it "should return an empty list" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task assigned to an organization the user is a member of is on hold" do
      let(:assignee) { Organization.find(create(:organization).id) }
      let(:expected_actions) { [] }

      before do
        allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true)
        task.update!(status: :on_hold)
      end

      it "should return an empty list" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "without a timed hold task" do
      it "doesn't include end timed hold in the returned actions" do
        expect(subject).to_not include task.build_action_hash(Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h, user)
      end
    end

    context "with a timed hold task" do
      let!(:timed_hold_task) do
        create(:timed_hold_task, appeal: task.appeal, assigned_to: user, days_on_hold: 18, parent: task)
      end

      it "includes end timed hold in the returned actions" do
        expect(subject).to include task.build_action_hash(Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h, user)
      end
    end
  end

  describe ".available_hearing_user_actions" do
    let!(:task) { create(:ama_task) }
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

  describe ".verify_user_can_update!" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:org) { create(:organization) }
    let(:other_org) { create(:organization) }
    let(:task) { create(:ama_task, :in_progress, assigned_to: assignee) }

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
    let(:task) { create(:ama_task, :in_progress, assigned_to: assignee) }

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
    let(:parent) { create(:ama_task, :in_progress, assigned_to: parent_assignee) }

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
      let(:parent) { create(:ama_task, :in_progress, assigned_to: org) }

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
    let(:org_task) { create(:ama_task, parent_id: root_task.id, assigned_to: org) }
    let(:task) { create(:ama_task, parent_id: org_task.id) }
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
      let(:task_type) { :ama_task }
      let(:closed_children_count) { 2 }
      let!(:completed_children) { create_list(task_type, closed_children_count / 2, :completed, parent_id: task.id) }
      let!(:cancelled_children) { create_list(task_type, closed_children_count / 2, :cancelled, parent_id: task.id) }
      let(:incomplete_children_count) { 2 }
      let!(:incomplete_children) { create_list(task_type, incomplete_children_count, parent_id: task.id) }

      before { task.on_hold! }

      it "reassign method should return list with old and new tasks and incomplete child tasks" do
        expect(subject.length).to eq(2 + incomplete_children_count)
      end

      it "incomplete children tasks are adopted by new task and completed tasks are not" do
        expect { subject }.to_not raise_error
        expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)

        new_task = task.parent.children.open.first
        expect(new_task.children.length).to eq(incomplete_children_count)
        expect(new_task.status).to eq(Constants.TASK_STATUSES.on_hold)

        task.reload
        expect(task.children.length).to eq(closed_children_count)
      end

      context "when the children are task timers" do
        let(:incomplete_children_count) { 1 }
        let(:task_type) { :timed_hold_task }

        it "children timer tasks are adopted by new task and not cancelled" do
          expect { subject }.to_not raise_error
          expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)

          new_task = task.parent.children.open.first
          expect(new_task.children.length).to eq(incomplete_children_count)
          expect(new_task.children.all?(&:assigned?)).to eq(true)
          expect(new_task.status).to eq(Constants.TASK_STATUSES.on_hold)

          task.reload
          expect(task.children.length).to eq(closed_children_count)
        end
      end

      context "when the children are attorney tasks" do
        let(:incomplete_children_count) { 1 }
        let(:task_type) { :ama_attorney_task }

        it "assigned AND completed child tasks are adopted by new task" do
          expect { subject }.to_not raise_error
          expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)

          new_task = task.parent.children.open.first
          expect(new_task.children.length).to eq(incomplete_children_count + closed_children_count / 2)
          expect(new_task.children.map(&:status)).to match_array(
            [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.completed]
          )
          expect(new_task.status).to eq(Constants.TASK_STATUSES.on_hold)

          task.reload
          expect(task.children.length).to eq(closed_children_count / 2)
          expect(task.children.map(&:status)).to match_array([Constants.TASK_STATUSES.cancelled])
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

  describe "timed hold task is cancelled when parent is updated" do
    let(:user) { create(:user) }
    let(:task) { create(:ama_task, assigned_to: user) }

    context "there is an active timed hold task child" do
      let!(:timed_hold_task) do
        create(:timed_hold_task, appeal: task.appeal, assigned_to: user, days_on_hold: 18, parent: task)
      end

      context "status is updated" do
        subject { task.update!(status: Constants.TASK_STATUSES.completed) }

        it "cancels the child timed hold task" do
          expect(timed_hold_task.reload.open?).to be_truthy

          subject

          expect(timed_hold_task.reload.cancelled?).to be_truthy
        end
      end

      context "a new child task is added" do
        let(:root_task) { create(:root_task) }
        let(:hearing_task) do
          create(
            :hearing_task,
            parent: root_task,
            appeal: root_task.appeal,
            assigned_to: HearingsManagement.singleton
          )
        end
        let(:task) do
          create(
            :assign_hearing_disposition_task,
            parent: hearing_task,
            appeal: root_task.appeal,
            assigned_to: user
          )
        end

        subject do
          TranscriptionTask.create!(
            appeal: root_task.appeal,
            parent: task,
            assigned_to: TranscriptionTeam.singleton
          )
        end

        it "cancels the child timed hold task" do
          expect(timed_hold_task.reload.open?).to be_truthy
          expect(task.reload.on_hold?).to be_truthy
          expect(task.reload.children.count).to eq 1

          subject

          expect(task.reload.children.count).to eq 2
          transcription_task = task.reload.children.find { |child| child.is_a?(TranscriptionTask) }
          expect(transcription_task).to_not be_nil
          expect(transcription_task.open?).to be_truthy
          expect(timed_hold_task.reload.cancelled?).to be_truthy
          expect(task.reload.on_hold?).to be_truthy
        end
      end

      context "instructions are updated" do
        subject { task.update!(instructions: ["These are my new instructions"]) }

        it "doesn not cancel the child timed hold task" do
          expect(timed_hold_task.reload.open?).to be_truthy
          expect(task.reload.on_hold?).to be_truthy

          subject

          expect(timed_hold_task.reload.open?).to be_truthy
          expect(task.reload.on_hold?).to be_truthy
        end
      end
    end
  end

  describe ".not_decisions_review" do
    let!(:veteran_record_request_task) { create(:veteran_record_request_task) }
    let!(:task) { create(:ama_task) }

    it "filters out subclasses of DecisionReviewTask" do
      tasks = described_class.not_decisions_review.all
      expect(tasks).to_not include(veteran_record_request_task)
      expect(tasks).to include(task)
    end
  end

  describe ".open?" do
    let(:trait) { nil }
    let(:task) { create(:ama_task, trait) }
    subject { task.open? }

    context "when status is assigned" do
      let(:trait) { :assigned }

      it "is open" do
        expect(subject).to eq(true)
      end
    end

    context "when status is in_progress" do
      let(:trait) { :in_progress }

      it "is open" do
        expect(subject).to eq(true)
      end
    end

    context "when status is on_hold" do
      let(:trait) { :on_hold }

      it "is open" do
        expect(subject).to eq(true)
      end
    end

    context "when status is completed" do
      let(:trait) { :completed }

      it "is not open" do
        expect(subject).to eq(false)
      end
    end

    context "when status is cancelled" do
      let(:trait) { :cancelled }

      it "is not open" do
        expect(subject).to eq(false)
      end
    end
  end

  describe ".active?" do
    let(:trait) { nil }
    let(:task) { create(:ama_task, trait) }
    subject { task.active? }

    context "when status is assigned" do
      let(:trait) { :assigned }

      it "is active" do
        expect(subject).to eq(true)
      end
    end

    context "when status is in_progress" do
      let(:trait) { :in_progress }

      it "is active" do
        expect(subject).to eq(true)
      end
    end

    context "when status is on_hold" do
      let(:trait) { :on_hold }

      it "is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when status is completed" do
      let(:trait) { :completed }

      it "is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when status is cancelled" do
      let(:trait) { :cancelled }

      it "is not active" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#actions_allowable?" do
    let(:user) { create(:user) }

    context "when task status is completed" do
      let(:task) { create(:ama_task, :completed) }

      it "returns false" do
        expect(task.actions_allowable?(user)).to eq(false)
      end
    end

    context "when user has subtask assigned to them" do
      let(:organization) { create(:organization) }
      let(:parent_task) { create(:ama_task, assigned_to: organization) }
      let!(:task) { create(:ama_task, assigned_to: user, parent: parent_task) }

      it "returns false" do
        organization.add_user(user)
        expect(parent_task.actions_allowable?(user)).to eq(false)
      end
    end
  end

  describe "#create_from_params" do
    let!(:judge) { create(:user) }
    let!(:attorney) { create(:user) }
    let!(:appeal) { create(:appeal) }
    let!(:task) { create(:task, type: Task.name, appeal: appeal) }
    let(:params) { { assigned_to: judge, appeal: task.appeal, parent_id: task.id, type: Task.name } }

    before do
      create(:staff, :judge_role, sdomainid: judge.css_id)
      create(:staff, :attorney_role, sdomainid: attorney.css_id)

      # Monkey patching might not be the best option, but we want to define a test_func
      # for our available actions unwrapper to call. This is the simplest way to do it
      class TaskActionRepository
        class << self
          def test_func(_task, _user)
            { type: Task.name }
          end
        end
      end

      allow_any_instance_of(Task)
        .to receive(:available_actions)
        .with(attorney)
        .and_return([{ label: "test label", value: "test/path", func: "test_func" }])
    end

    subject { Task.create_from_params(params, attorney) }

    it "the parent task status should be 'on hold'" do
      expect(task.status).to eq("assigned")
      new_task = subject
      expect(new_task.parent_id).to eq(task.id)
      expect(task.reload.status).to eq("on_hold")
    end

    context "the task is attached to a legacy appeal" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      it "the parent task is 'on hold'" do
        expect(task.status).to eq("assigned")
        new_task = subject
        expect(new_task.parent_id).to eq(task.id)
        expect(task.reload.status).to eq("on_hold")
      end
    end

    context "when the instructions field is a string" do
      let(:instructions_text) { "instructions for this task" }
      let(:params) do
        { assigned_to: judge, appeal: task.appeal, parent_id: task.id, type: "Task", instructions: instructions_text }
      end

      it "should transform it into an array of strings" do
        expect(subject.instructions).to eq([instructions_text])
      end
    end

    context "the params are incomplete" do
      let(:params) { { assigned_to: judge, appeal: nil, parent_id: nil, type: Task.name } }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find Task without an ID/)
      end
    end

    context "when the task assignee is not active" do
      let(:inactive_user) { create(:user, status: Constants.USER_STATUSES.inactive) }
      let(:params) do
        { assigned_to: inactive_user, appeal: task.appeal, parent_id: task.id }
      end

      it "should throw an error" do
        expect { subject }.to raise_error(
          Caseflow::Error::InvalidAssigneeStatusOnTaskCreate,
          "#{inactive_user.full_name} is marked as inactive in Caseflow. Please select another user assignee or " \
          "contact support if you believe you're getting this message in error."
        )
      end
    end
  end

  describe ".create_and_auto_assign_child_task" do
    subject { create(:task, assigned_to: org, appeal: create(:appeal)) }

    context "when the task is assigned to an organization that automatically assigns tasks to its members" do
      class AutoAssignOrg < Organization
        attr_accessor :assignee

        def next_assignee(_options = {})
          assignee
        end
      end

      let(:user) { create(:user) }
      let(:org) { AutoAssignOrg.create!(url: "autoassign", name: "AutoAssign", assignee: user) }

      it "should create a child task when a task assigned to the organization is created" do
        expect(subject.children.length).to eq(1)
      end
    end

    context "when the task is assigned to an organization that does not automatically assign tasks to its members" do
      let(:org) { create(:organization) }

      it "should not create a child task when a task assigned to the organization is created" do
        expect(subject.children).to eq([])
      end
    end
  end

  describe "#verify_user_can_create!" do
    let(:user) { create(:user) }
    let(:task) { create(:ama_task) }

    before do
      allow(task).to receive(:available_actions).and_return(dummy_actions)
    end

    context "when task has an available action" do
      let(:dummy_actions) do
        [
          { label: "test label", value: "test/path", func: "assign_to_attorney_data" }
        ]
      end

      it "should not throw an error" do
        expect { AttorneyTask.verify_user_can_create!(user, task) }.to_not raise_error
      end

      context "when task is completed" do
        it "should throw an error" do
          task.update!(status: :completed)
          expect { AttorneyTask.verify_user_can_create!(user, task) }.to raise_error(
            Caseflow::Error::ActionForbiddenError
          )
        end
      end
    end

    context "when task has no available actions with AttorneyTask type" do
      let(:dummy_actions) do
        [
          { label: "test label", value: "test/path", func: "assign_to_privacy_team_data" }
        ]
      end

      it "should throw an error" do
        expect { AttorneyTask.verify_user_can_create!(user, task) }.to raise_error(
          Caseflow::Error::ActionForbiddenError
        )
      end
    end

    context "when task has no available actions" do
      let(:dummy_actions) { [] }

      it "should throw an error" do
        expect { AttorneyTask.verify_user_can_create!(user, task) }.to raise_error(
          Caseflow::Error::ActionForbiddenError
        )
      end
    end
  end

  describe ".set_timestamps" do
    let(:task) { create(:task) }

    context "when status changes to in_progress" do
      let(:status) { Constants.TASK_STATUSES.in_progress }

      it "should set started_at timestamp" do
        expect(task.started_at).to eq(nil)
        task.update!(status: status)
        expect(task.started_at).to_not eq(nil)
      end
    end

    context "when status changes to on_hold" do
      let(:status) { Constants.TASK_STATUSES.on_hold }

      it "should set placed_on_hold_at timestamp" do
        expect(task.placed_on_hold_at).to eq(nil)
        task.update!(status: status)
        expect(task.placed_on_hold_at).to_not eq(nil)
      end
    end

    context "when status changes to completed" do
      let(:status) { Constants.TASK_STATUSES.completed }

      it "should set closed_at timestamp" do
        expect(task.closed_at).to eq(nil)
        task.update!(status: status)
        expect(task.closed_at).to_not eq(nil)
      end
    end

    context "when status changes to cancelled" do
      let(:status) { Constants.TASK_STATUSES.cancelled }

      it "should set closed_at timestamp" do
        expect(task.closed_at).to eq(nil)
        task.update!(status: status)
        expect(task.closed_at).to_not eq(nil)
      end
    end

    context "when a timestamp is passed" do
      it "should set passed timestamps" do
        two_weeks_ago = 2.weeks.ago
        expect(task.placed_on_hold_at).to eq(nil)
        task.update!(status: Constants.TASK_STATUSES.on_hold, placed_on_hold_at: two_weeks_ago)
        expect(task.placed_on_hold_at).to eq(two_weeks_ago)

        # change status to completed
        one_week_ago = 1.week.ago
        task.update!(status: Constants.TASK_STATUSES.completed, closed_at: one_week_ago)
        expect(task.closed_at).to eq(one_week_ago)

        # change the status back to on hold and ensure timestamp is updated
        task.update!(status: Constants.TASK_STATUSES.on_hold, placed_on_hold_at: one_week_ago)
        expect(task.placed_on_hold_at).to eq(one_week_ago)

        task.update!(status: Constants.TASK_STATUSES.in_progress, started_at: two_weeks_ago)
        expect(task.started_at).to eq(two_weeks_ago)
      end
    end

    context "when task is closed and is re-opened" do
      let(:task) { create(:task, :cancelled) }

      it "sets closed_at to nil" do
        expect(task.cancelled?).to eq(true)
        expect(task.closed_at).to_not be_nil

        task.on_hold!

        expect(task.on_hold?).to eq(true)
        expect(task.closed_at).to be_nil
      end
    end
  end

  describe "task timer relationship" do
    let(:task) { create(:ama_task) }
    let(:task_id) { task.id }
    let(:task_timer_count) { 4 }
    let!(:task_timers) { Array.new(task_timer_count) { TaskTimer.create!(task: task, last_submitted_at: 2.days.ago) } }

    it "returns and destroys related timers" do
      expect(TaskTimer.where(task_id: task_id).count).to eq(task_timer_count)
      expect(task.task_timers.to_a).to match_array(task_timers)

      task.destroy!
      expect(TaskTimer.where(task_id: task_id).count).to eq(0)
    end

    it "cancels related timers on cancel" do
      task.update!(status: Constants.TASK_STATUSES.cancelled)
      task.task_timers.each do |task_timer|
        expect(task_timer.canceled_at).not_to eq(nil)
      end
    end
  end

  describe ".assigned_to_same_org?" do
    subject { task.assigned_to_same_org?(other_task) }

    before { Colocated.singleton.add_user(create(:user)) }

    context "when other task is assigned to a user" do
      let(:task) { create(:task, assigned_to: Colocated.singleton) }
      let(:other_task) { create(:task, assigned_to: create(:user)) }

      it "should be false" do
        expect(subject).to eq(false)
      end
    end

    context "when other task is assigned to another org" do
      let(:task) { create(:task, assigned_to: Colocated.singleton) }
      let(:other_task) { create(:task, assigned_to: MailTeam.singleton) }

      it "should be false" do
        expect(subject).to eq(false)
      end
    end

    context "when other task is assigned to same org" do
      let(:task) { create(:task, assigned_to: Colocated.singleton) }
      let(:other_task) { create(:task, assigned_to: Colocated.singleton) }

      it "should be true" do
        expect(subject).to eq(true)
      end
    end
  end

  describe ".first_ancestor_of_type" do
    let(:user) { create(:user) }

    subject { task.first_ancestor_of_type }

    context "when the task has no parents of the same type" do
      let(:task) { create(:colocated_task, parent: create(:root_task), assigned_to: user) }

      it "should should return itself" do
        expect(subject.id).to eq(task.id)
      end
    end

    context "when the task has a grandparent of the same type, but a different parent" do
      let(:grandparent_task) { create(:colocated_task, :ihp, assigned_to: user) }
      let(:parent_task) { create(:ama_judge_task, parent: grandparent_task, assigned_to: user) }
      let(:task) { create(:colocated_task, :ihp, parent: parent_task, assigned_to: user) }

      it "should should return itself" do
        expect(subject.id).to eq(task.id)
      end
    end

    context "when the task has both a parent and grandparent of the same type" do
      let(:grandparent_task) { create(:colocated_task, :ihp, assigned_to: user) }
      let(:parent_task) { create(:colocated_task, :ihp, parent: grandparent_task, assigned_to: user) }
      let(:task) { create(:colocated_task, :ihp, parent: parent_task, assigned_to: user) }

      it "should should return the grandparent" do
        expect(subject.id).to eq(grandparent_task.id)
      end
    end
  end

  describe ".last_descendant_of_type" do
    let(:user) { create(:user) }

    subject { task.last_descendant_of_type }

    context "when the task has no children of the same type" do
      let(:task) { create(:colocated_task, assigned_to: user) }
      let(:child_task) { create(:ama_judge_task, parent: task) }

      it "should should return itself" do
        expect(subject.id).to eq(task.id)
      end
    end

    context "when the task has a grandchild of the same type, but a different child" do
      let(:task) { create(:colocated_task, :ihp, assigned_to: user) }
      let(:child_task) { create(:ama_judge_task, type: JudgeAssignTask.name, parent: task) }
      let(:grandchild_task) { create(:colocated_task, :ihp, parent: child_task, assigned_to: user) }

      it "should should return itself" do
        expect(subject.id).to eq(task.id)
      end
    end

    context "when the task has both a parent and grandparent of the same type" do
      let(:task) { create(:colocated_task, :ihp, assigned_to: user) }
      let(:child_task) { create(:colocated_task, :ihp, parent: task, assigned_to: user) }
      let!(:grandchild_task) { create(:colocated_task, :ihp, parent: child_task, assigned_to: user) }

      it "should should return the grandchild" do
        expect(subject.id).to eq(grandchild_task.id)
      end
    end
  end

  describe ".when_child_task_created" do
    let(:parent_task) { create(:task, appeal: create(:appeal)) }

    subject { create(:task, parent: parent_task, appeal: parent_task.appeal) }

    before do
      allow(Raven).to receive(:capture_message)
    end

    context "when the task is active" do
      it "does not send a message to Sentry" do
        expect(parent_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(parent_task.children.count).to eq(0)

        subject

        expect(Raven).to have_received(:capture_message).exactly(0).times
        expect(parent_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(parent_task.children.count).to eq(1)
      end
    end

    context "when the task is closed" do
      before { parent_task.update!(status: Constants.TASK_STATUSES.completed) }

      it "sends a message to Sentry" do
        expect(parent_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(parent_task.children.count).to eq(0)

        subject

        expect(Raven).to have_received(:capture_message).exactly(1).times
        expect(parent_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(parent_task.children.count).to eq(1)
      end
    end
  end
end
