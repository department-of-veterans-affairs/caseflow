describe Task do
  context ".find_by_department" do
    let(:department) { :dispatch }
    subject { Task.find_by_department(department) }

    it "filters to tasks in the department" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.to_sql).to include("CreateEndProduct")
    end
  end
end
