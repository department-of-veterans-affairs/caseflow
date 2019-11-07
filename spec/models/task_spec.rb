# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Task, :all_dbs do
  context "includes PrintsTaskTree concern" do
    describe ".structure" do
      let(:root_task) { create(:root_task, :on_hold) }
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

  describe ".when_child_task_completed" do
    let(:task) { create(:task, :on_hold, type: Task.name) }
    let(:child) { create(:task, :completed, type: Task.name, parent: task) }

    subject { task.when_child_task_completed(child) }

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
        let(:child) { create(:task, :in_progress, type: Task.name, parent_id: task.id) }

        it "should not change the task's status" do
          status_before = task.status
          subject
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 complete child task" do
        let(:child) { create(:task, :completed, type: Task.name, parent_id: task.id) }

        it "should change task's status to assigned" do
          status_before = task.status
          subject
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end

      context "when task is already closed" do
        let!(:task) { create(:task, :on_hold, type: Task.name) }
        let!(:child) { create(:task, :completed, type: Task.name, parent: task) }

        before { task.update!(status: Constants.TASK_STATUSES.completed) }

        it "does not change the status of the task" do
          subject
          expect(task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        let!(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }
        let(:incomplete_children) do
          create_list(:task, 2, :in_progress, type: Task.name, parent_id: task.id)
        end
        let(:child) { incomplete_children.last }

        it "should not change the task's status" do
          status_before = task.status
          subject
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has only complete child tasks" do
        let(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }
        let(:child) { completed_children.last }

        it "should change task's status to assigned" do
          status_before = task.status
          subject
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end
    end

    context "when on_hold task is assigned to an organization" do
      let(:organization) { Organization.create!(name: "Other organization", url: "other") }
      let(:task) { create(:task, :on_hold, type: Task.name, assigned_to: organization) }

      context "when task has no child tasks" do
        let(:child) { nil }

        it "should not update any attribute of the task" do
          task_status = task.status
          subject
          expect(task.reload.status).to eq task_status
        end
      end

      context "when task has 1 incomplete child task" do
        let(:child) { create(:task, :in_progress, type: Task.name, parent_id: task.id) }

        it "should not update any attribute of the task" do
          task_status = task.status
          subject
          expect(task.reload.status).to eq task_status
        end
      end

      context "when task has 1 complete child task" do
        let(:child) { create(:task, :completed, type: Task.name, parent_id: task.id) }

        it "should update the task" do
          subject
          expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        end
      end

      context "when task is already closed" do
        let!(:task) { create(:task, :on_hold, type: Task.name, assigned_to: organization) }
        let!(:child) { create(:task, :completed, type: Task.name, parent: task) }

        before { task.update!(status: Constants.TASK_STATUSES.completed) }

        it "does not change the status of the task" do
          subject
          expect(task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        let!(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }
        let(:incomplete_children) do
          create_list(:task, 2, :in_progress, type: Task.name, parent_id: task.id)
        end
        let(:child) { incomplete_children.last }

        it "should not update any attribute of the task" do
          task_status = task.status
          subject
          expect(task.reload.status).to eq task_status
        end
      end

      context "when task has only complete child tasks" do
        let(:completed_children) { create_list(:task, 3, :completed, type: Task.name, parent_id: task.id) }
        let(:child) { completed_children.last }

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
      let(:task) { create(:generic_task, assigned_to: user) }

      it { is_expected.to be_truthy }
    end

    context "when user does not have access" do
      let(:user) { create(:user) }
      let(:task) { create(:generic_task, assigned_to: create(:user)) }

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
      top_level_task.reload.cancel_task_and_child_subtasks

      [top_level_task, *second_level_tasks, *third_level_task].each do |task|
        expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      end
    end
  end

  describe ".root_task" do
    context "when sub-sub-sub...task has a root task" do
      let(:root_task) { create(:root_task) }
      let(:task) do
        t = create(:generic_task, parent_id: root_task.id)
        5.times { t = create(:generic_task, parent_id: t.id) }
        Task.last
      end

      it "should return the root_task" do
        expect(task.root_task.id).to eq(root_task.id)
      end
    end

    context "when sub-sub-sub...task does not have a root task" do
      let(:task) do
        t = create(:generic_task)
        5.times { t = create(:generic_task, parent_id: t.id) }
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
    let(:parent_task) { create(:generic_task) }

    subject { parent_task.reload.descendants }

    context "when a task has some descendants" do
      let(:children_count) { 6 }
      let(:grandkids_per_child) { 4 }
      let(:children) { create_list(:generic_task, children_count, parent: parent_task) }

      before { children.each { |t| create_list(:generic_task, grandkids_per_child, parent: t) } }

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

  describe ".available_actions_unwrapper" do
    let(:user) { create(:user) }
    let(:task) { create(:generic_task, assigned_to: user) }

    context "without a timed hold task" do
      it "doesn't include end timed hold in the returned actions" do
        actions = task.available_actions_unwrapper(user)
        expect(actions).to_not include task.build_action_hash(Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h, user)
      end
    end

    context "with a timed hold task" do
      let!(:timed_hold_task) do
        create(:timed_hold_task, appeal: task.appeal, assigned_to: user, days_on_hold: 18, parent: task)
      end

      it "includes end timed hold in the returned actions" do
        actions = task.available_actions_unwrapper(user)
        expect(actions).to include task.build_action_hash(Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h, user)
      end
    end
  end

  describe "timed hold task is cancelled when parent is updated" do
    let(:user) { create(:user) }
    let(:task) { create(:generic_task, assigned_to: user) }

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
    let!(:task) { create(:generic_task) }

    it "filters out subclasses of DecisionReviewTask" do
      tasks = described_class.not_decisions_review.all
      expect(tasks).to_not include(veteran_record_request_task)
      expect(tasks).to include(task)
    end
  end

  describe ".open?" do
    let(:trait) { nil }
    let(:task) { create(:generic_task, trait) }
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
    let(:task) { create(:generic_task, trait) }
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

  describe "#actions_available?" do
    let(:user) { create(:user) }

    context "when task status is on_hold" do
      let(:task) { create(:generic_task, :on_hold) }

      it "returns false" do
        expect(task.actions_available?(user)).to eq(false)
      end
    end
  end

  describe "#actions_allowable?" do
    let(:user) { create(:user) }

    context "when task status is completed" do
      let(:task) { create(:generic_task, :completed) }

      it "returns false" do
        expect(task.actions_allowable?(user)).to eq(false)
      end
    end

    context "when user has subtask assigned to them" do
      let(:organization) { create(:organization) }
      let(:parent_task) { create(:generic_task, assigned_to: organization) }
      let!(:task) { create(:generic_task, assigned_to: user, parent: parent_task) }

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
    let(:task) { create(:generic_task) }

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
  end

  describe "task timer relationship" do
    let(:task) { create(:generic_task) }
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

  describe ".old_style_hold_expired?" do
    subject { task.old_style_hold_expired? }

    context "when a task is on an active old-style hold" do
      let(:task) { create(:task, :on_hold) }

      it "recognizes that the old style hold has not expired" do
        expect(subject).to eq(false)
      end
    end

    context "when a task has completed an old-style hold" do
      let(:task) { create(:task, :on_hold) }

      it "recognizes that the old style hold has expired" do
        task.update(placed_on_hold_at: 200.days.ago)
        expect(subject).to eq(true)
      end
    end

    context "when a task has a completed old-style hold as well as a new timed hold" do
      let(:task) { create(:task, :on_hold, placed_on_hold_at: 200.days.ago) }
      before { TimedHoldTask.create_from_parent(task, days_on_hold: 16) }

      it "does not recognize that the task has completed the old-style hold" do
        expect(subject).to eq(false)
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
