describe Task do
  describe ".when_child_task_completed" do
    context "when on_hold task is assigned to a person" do
      let(:task) { FactoryBot.create(:task, :on_hold, type: "Task") }
      context "when task has no child tasks" do
        it "should not change the task's status" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 incomplete child task" do
        before { FactoryBot.create(:task, :in_progress, type: "Task", parent_id: task.id) }
        it "should not change the task's status" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has 1 complete child task" do
        before { FactoryBot.create(:task, :completed, type: "Task", parent_id: task.id) }
        it "should change task's status to assigned" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        before do
          FactoryBot.create_list(:task, 3, :completed, type: "Task", parent_id: task.id)
          FactoryBot.create_list(:task, 2, :in_progress, type: "Task", parent_id: task.id)
        end
        it "should not change the task's status" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to eq(status_before)
        end
      end

      context "when task has only complete child tasks" do
        before { FactoryBot.create_list(:task, 4, :completed, type: "Task", parent_id: task.id) }
        it "should change task's status to assigned" do
          status_before = task.status
          task.when_child_task_completed
          expect(task.status).to_not eq(status_before)
          expect(task.status).to eq("assigned")
        end
      end
    end

    context "when on_hold task is assigned to an organization" do
      let(:organization) { Organization.create! }
      let(:task) { FactoryBot.create(:task, :on_hold, type: "Task", assigned_to: organization) }
      context "when task has no child tasks" do
        it "should not update any attribute of the task" do
          expect_any_instance_of(Task).to_not receive(:update!)
          task.when_child_task_completed
        end
      end

      context "when task has 1 incomplete child task" do
        before { FactoryBot.create(:task, :in_progress, type: "Task", parent_id: task.id) }
        it "should not update any attribute of the task" do
          expect_any_instance_of(Task).to_not receive(:update!)
          task.when_child_task_completed
        end
      end

      context "when task has 1 complete child task" do
        before { FactoryBot.create(:task, :completed, type: "Task", parent_id: task.id) }
        it "should update the task" do
          expect_any_instance_of(Task).to receive(:update!)
          task.when_child_task_completed
        end
      end

      context "when task has some complete and some incomplete child tasks" do
        before do
          FactoryBot.create_list(:task, 3, :completed, type: "Task", parent_id: task.id)
          FactoryBot.create_list(:task, 2, :in_progress, type: "Task", parent_id: task.id)
        end
        it "should not update any attribute of the task" do
          expect_any_instance_of(Task).to_not receive(:update!)
          task.when_child_task_completed
        end
      end

      context "when task has only complete child tasks" do
        before { FactoryBot.create_list(:task, 4, :completed, type: "Task", parent_id: task.id) }
        it "should update the task" do
          expect_any_instance_of(Task).to receive(:update!)
          task.when_child_task_completed
        end
      end
    end
  end

  describe "#can_be_updated_by_user?" do
    subject { task.can_be_updated_by_user?(user) }

    context "when user is an assignee" do
      let(:user) { create(:user) }
      let(:task) { create(:generic_task, assigned_to: user).becomes(GenericTask) }

      it { is_expected.to be_truthy }
    end

    context "when user does not have access" do
      let(:user) { create(:user) }
      let(:task) { create(:generic_task, assigned_to: create(:user)) }

      it { is_expected.to be(false) }
    end
  end

  describe "#prepared_by_display_name" do
    let(:task) { create(:task, type: "Task") }

    context "when there is no attorney_case_review" do
      it "should return nil" do
        expect(task.prepared_by_display_name).to eq(nil)
      end
    end

    context "when there is an attorney_case_review" do
      let!(:child) { create(:task, type: "Task", appeal: task.appeal, parent_id: task.id) }
      let!(:attorney_case_reviews) do
        create(:attorney_case_review, task_id: child.id, attorney: create(:user, full_name: "Bob Smith"))
      end

      it "should return the most recent attorney case review" do
        expect(task.prepared_by_display_name).to eq(%w[Bob Smith])
      end
    end
  end

  describe "#latest_attorney_case_review" do
    let(:task) { create(:task, type: "Task") }

    context "when there is no sub task" do
      it "should return nil" do
        expect(task.latest_attorney_case_review).to eq(nil)
      end
    end

    context "when there is a sub task" do
      let!(:child) { create(:task, type: "Task", appeal: task.appeal, parent_id: task.id) }
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

  describe "#assign_to_user_data" do
    let(:organization) { create(:organization, name: "Organization") }
    let(:users) { create_list(:user, 3) }

    before do
      allow(organization).to receive(:users).and_return(users)
    end

    context "when assigned_to is an organization" do
      let(:task) { create(:generic_task, assigned_to: organization) }

      it "should return all members" do
        expect(task.assign_to_user_data[:options]).to match_array(users.map { |u| { label: u.full_name, value: u.id } })
      end

      it "should return the task type of task" do
        expect(task.assign_to_user_data[:type]).to eq(task.type)
      end
    end

    context "when assigned_to's parent is an organization" do
      let(:parent) { create(:generic_task, assigned_to: organization) }
      let(:task) { create(:generic_task, assigned_to: users.first, parent: parent) }

      it "should return all members except user" do
        user_output = users[1..users.length - 1].map { |u| { label: u.full_name, value: u.id } }
        expect(task.assign_to_user_data[:options]).to match_array(user_output)
      end
    end

    context "when assigned_to is a user" do
      let(:task) { create(:generic_task, assigned_to: users.first) }

      it "should return all members except user" do
        expect(task.assign_to_user_data[:options]).to match_array([])
      end
    end
  end

  describe "#return_to_attorney_data" do
    let(:attorney) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Janet Avilez") }
    let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let(:judge) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
    let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:judge_task) { FactoryBot.create(:ama_judge_decision_review_task, assigned_to: judge) }
    let!(:attorney_task) do
      FactoryBot.create(:ama_attorney_task, assigned_to: attorney, parent: judge_task, appeal: judge_task.appeal)
    end

    subject { judge_task.return_to_attorney_data }

    context "there aren't any attorneys on the JudgeTeam" do
      it "still shows the assigned attorney in selected and options" do
        expect(subject[:selected]).to eq attorney
        expect(subject[:options]).to eq [{ label: attorney.full_name, value: attorney.id }]
      end
    end

    context "there are attorneys on the JudgeTeam" do
      let(:attorney_names) { ["Jesse Abrecht", "Brenda Akery", "Crystal Andregg"] }

      before do
        OrganizationsUser.add_user_to_organization(attorney, judge_team)

        attorney_names.each do |attorney_name|
          another_attorney_on_the_team = FactoryBot.create(
            :user, station_id: User::BOARD_STATION_ID, full_name: attorney_name
          )
          FactoryBot.create(:staff, :attorney_role, user: another_attorney_on_the_team)
          OrganizationsUser.add_user_to_organization(another_attorney_on_the_team, judge_team)
        end
      end

      it "shows the assigned attorney in selected, and all attorneys in options" do
        expect(subject[:selected]).to eq attorney
        expect(judge_team.non_admins.count).to eq attorney_names.count + 1
        judge_team.non_admins.each do |team_attorney|
          expect(subject[:options]).to include(label: team_attorney.full_name, value: team_attorney.id)
        end
      end
    end
  end

  describe ".root_task" do
    context "when sub-sub-sub...task has a root task" do
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:task) do
        t = FactoryBot.create(:generic_task, parent_id: root_task.id)
        5.times { t = FactoryBot.create(:generic_task, parent_id: t.id) }
        GenericTask.last
      end

      it "should return the root_task" do
        expect(task.root_task.id).to eq(root_task.id)
      end
    end

    context "when sub-sub-sub...task does not have a root task" do
      let(:task) do
        t = FactoryBot.create(:generic_task)
        5.times { t = FactoryBot.create(:generic_task, parent_id: t.id) }
        GenericTask.last
      end

      it "should throw an error" do
        expect { task.root_task }.to(raise_error) do |e|
          expect(e).to be_a(Caseflow::Error::NoRootTask)
          expect(e.message).to eq("Could not find root task for task with ID #{task.id}")
        end
      end
    end

    context "task is root task" do
      let(:task) { FactoryBot.create(:root_task) }
      it "should return itself" do
        expect(task.root_task.id).to eq(task.id)
      end
    end
  end

  describe ".available_actions_unwrapper" do
    context "when task/user combination result in multiple available actions with same path" do
      let(:user) { FactoryBot.create(:user) }
      let(:task) { FactoryBot.create(:generic_task) }

      let(:path) { "modal/path_to_modal" }
      let(:labels) { ["First option", "Second option"] }

      before do
        allow(task).to receive(:actions_available?).and_return(true)

        dummy_actions = [
          { label: labels[0], value: path },
          { label: labels[1], value: path }
        ]
        allow(task).to receive(:available_actions).and_return(dummy_actions)
      end

      it "should throw an error" do
        expect { task.available_actions_unwrapper(user) }.to(raise_error) do |e|
          expect(e).to be_a(Caseflow::Error::DuplicateTaskActionPaths)
          expect(e.task_id).to eq(task.id)
          expect(e.user_id).to eq(user.id)
          expect(e.labels).to match_array(labels)
        end
      end
    end
  end

  describe ".active?" do
    let(:status) { nil }
    let(:task) { FactoryBot.create(:generic_task, status: status) }
    subject { task.active? }

    context "when status is assigned" do
      let(:status) { Constants.TASK_STATUSES.assigned }

      it "is active" do
        expect(subject).to eq(true)
      end
    end

    context "when status is in_progress" do
      let(:status) { Constants.TASK_STATUSES.in_progress }

      it "is active" do
        expect(subject).to eq(true)
      end
    end

    context "when status is on_hold" do
      let(:status) { Constants.TASK_STATUSES.on_hold }

      it "is active" do
        expect(subject).to eq(true)
      end
    end

    context "when status is completed" do
      let(:status) { Constants.TASK_STATUSES.completed }

      it "is not active" do
        expect(subject).to eq(false)
      end
    end

    context "when status is cancelled" do
      let(:status) { Constants.TASK_STATUSES.cancelled }

      it "is not active" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#actions_available?" do
    let(:user) { create(:user) }

    context "when task status is on_hold" do
      let(:task) { create(:generic_task, status: "on_hold") }

      it "returns false" do
        expect(task.actions_available?(user)).to eq(false)
      end
    end
  end

  describe "#actions_allowable?" do
    let(:user) { create(:user) }

    context "when task status is completed" do
      let(:task) { create(:generic_task, status: "completed") }

      it "returns false" do
        expect(task.actions_allowable?(user)).to eq(false)
      end
    end

    context "when user has subtask assigned to them" do
      let(:organization) { create(:organization) }
      let(:parent_task) { create(:generic_task, assigned_to: organization) }
      let!(:task) { create(:generic_task, assigned_to: user, parent: parent_task) }

      it "returns false" do
        OrganizationsUser.add_user_to_organization(user, organization)
        expect(parent_task.actions_allowable?(user)).to eq(false)
      end
    end
  end

  describe "#create_from_params" do
    let!(:judge) { FactoryBot.create(:user) }
    let!(:attorney) { FactoryBot.create(:user) }
    let!(:appeal) { FactoryBot.create(:appeal) }
    let!(:task) { FactoryBot.create(:task, type: "Task", appeal: appeal) }
    let(:params) { { assigned_to: judge, appeal: task.appeal, parent_id: task.id, type: "Task" } }

    before do
      FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)

      # Monkey patching might not be the best option, but we want to define a test_func
      # for our available actions unwrapper to call. This is the simplest way to do it
      class Task
        def test_func(_user)
          { type: Task.name }
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
      let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: create(:case)) }

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
      let(:params) { { assigned_to: judge, appeal: nil, parent_id: task.id, type: "Task" } }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /Appeal can't be blank/)
      end
    end
  end

  describe ".create_and_auto_assign_child_task" do
    subject { Task.create!(assigned_to: org, appeal: FactoryBot.create(:appeal), type: Task.name) }

    context "when the task is assigned to an organization that automatically assigns tasks to its members" do
      class AutoAssignOrg < Organization
        attr_accessor :assignee

        def next_assignee(_options = {})
          assignee
        end
      end

      let(:user) { FactoryBot.create(:user) }
      let(:org) { AutoAssignOrg.create(assignee: user) }

      it "should create a child task when a task assigned to the organization is created" do
        expect(subject.children.length).to eq(1)
      end
    end

    context "when the task is assigned to an organization that does not automatically assign tasks to its members" do
      let(:org) { FactoryBot.create(:organization) }

      it "should not create a child task when a task assigned to the organization is created" do
        expect(subject.children).to eq([])
      end
    end
  end

  describe "#verify_user_can_create!" do
    let(:user) { FactoryBot.create(:user) }
    let(:task) { FactoryBot.create(:generic_task) }

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
        expect { AttorneyTask.verify_user_can_create!(user, task) }.to_not raise_error(
          Caseflow::Error::ActionForbiddenError
        )
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
    let(:task) { FactoryBot.create(:task) }

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
  end
end
