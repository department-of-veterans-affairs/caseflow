class FakeTask < Task
end

describe Task do
  # Clear the task from the DB before every test
  before do
    reset_application!
    @user = User.create(station_id: "ABC", css_id: "123")
    @appeal = Appeal.create(vacols_id: "123C")
    @appeal2 = Appeal.create(vacols_id: "456D")
    @task = CreateEndProduct.create(appeal: @appeal)
    @task2 = CreateEndProduct.create(appeal: @appeal2)
  end

  context ".find_by_department" do
    before do
      appeal = Appeal.create(vacols_id: "fake")
      FakeTask.create(appeal: appeal)
    end
    let(:department) { :dispatch }
    subject { Task.find_by_department(department) }

    it "filters to tasks in the department" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(Task.count).to eq(3)
      expect(subject.count).to eq(2)
    end
  end

  context ".newest_first" do
    subject { Task.newest_first }
    before do
      @task.update(created_at: 10.days.ago)
      @task2.update(created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(@task2)
      expect(subject.last).to eq(@task)
    end
  end

  context ".unassigned" do
    before do
      @task.update(user: User.create(css_id: "111", station_id: "abc"))
    end
    subject { Task.unassigned }

    it "filters by nil user_id" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.count).to eq(1)
      expect(subject.first).to eq(@task2)
    end
  end

  context "Assigning user methods" do
    subject { @task }

    context ".assign" do
      before { @task.assign(@user) }

      it "correctly assigns a task to a user" do
        expect(subject.user.id).to eq(@user.id)
        expect(subject.assigned_at).not_to be_nil
      end
    end

    context ".assigned?" do
      it "assigned is false before assignment" do
        expect(subject.assigned?).to be_falsey
      end

      it "assigned is true after assignment" do
        @task.assign(@user)
        expect(subject.assigned?).to be_truthy
      end
    end
  end

  context ".progress_status" do
    subject { @task }

    # We start with a blank task and move it task through the various states

    it "Walk through different task states" do
      expect(subject.progress_status).to eq("Unassigned")
      @task.assign(@user)
      expect(subject.progress_status).to eq("Not Started")
      # TODO(Mark): When we have a way to start a task, this should be updated
      @task.started_at = Time.now.utc
      expect(subject.progress_status).to eq("In Progress")
      @task.completed_at = Time.now.utc
      expect(subject.progress_status).to eq("Complete")
    end
  end

  context ".completed?" do
    subject { @task }
    before { @task.completed_at = Time.now.utc }
    it { expect(subject.completed_at).to be_truthy }
  end

  context "#completed_today" do
    before do
      @task.update_attributes!(completed_at: Time.now.utc)
    end
    it { expect { Task.completed_today.find(@task.id) }.not_to raise_error }
  end

  context "#to_complete" do
    it { expect { Task.to_complete.find(@task.id) }.not_to raise_error }
  end
end
