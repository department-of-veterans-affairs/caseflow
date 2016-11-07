class FakeTask < Task
end

describe Task do
  before do
    reset_application!

    appeal = Appeal.create(vacols_id: "123C")
    appeal2 = Appeal.create(vacols_id: "456D")
    @task1 = CreateEndProduct.create(appeal: appeal)
    @task2 = CreateEndProduct.create(appeal: appeal2)
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
      @task1.update(created_at: 10.days.ago)
      @task2.update(created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(@task2)
      expect(subject.last).to eq(@task1)
    end
  end

  context ".unassigned" do
    before do
      @task1.update(user: User.create(css_id: "111", station_id: "abc"))
    end
    subject { Task.unassigned }

    it "filters by nil user_id" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.count).to eq(1)
      expect(subject.first).to eq(@task2)
    end
  end
end
