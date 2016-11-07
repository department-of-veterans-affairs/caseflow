describe Task do
  before do
    reset_application!
  end

  context ".find_by_department" do
    let(:department) { :dispatch }
    subject { Task.find_by_department(department) }

    it "filters to tasks in the department" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.to_sql).to include("\"tasks\".\"type\" = 'CreateEndProduct'")
    end
  end

  context ".newest_first" do
    subject { Task.newest_first }
    before do
      appeal = Appeal.create(vacols_id: "123C")
      appeal2 = Appeal.create(vacols_id: "456D")
      @oldest = CreateEndProduct.create(appeal: appeal, created_at: 10.days.ago)
      @newest = CreateEndProduct.create(appeal: appeal2, created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(@newest)
      expect(subject.last).to eq(@oldest)
    end
  end

  context ".unassigned" do
    subject { Task.unassigned }

    it "filters by user_id" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.to_sql).to include("\"tasks\".\"user_id\" IS NULL")
    end
  end
end
