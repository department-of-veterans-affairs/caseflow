describe QueueRepository do
  context ".filter_duplicate_tasks" do
    subject { QueueRepository.filter_duplicate_tasks(tasks) }

    let(:tasks) do
      [
        OpenStruct.new(vacols_id: "123C", assigned_to_attorney_date: 3.days.ago),
        OpenStruct.new(vacols_id: "123B", assigned_to_attorney_date: 5.days.ago),
        OpenStruct.new(vacols_id: "123C", assigned_to_attorney_date: 2.days.ago),
        OpenStruct.new(vacols_id: "123C", assigned_to_attorney_date: 9.days.ago),
        OpenStruct.new(vacols_id: "123A", assigned_to_attorney_date: 9.days.ago)
      ]
    end

    it "should filter duplicate tasks and keep the latest" do
      expect(subject.size).to eq 3
      expect(subject).to include tasks.third
      expect(subject).to include tasks.second
      expect(subject).to include tasks.last
    end
  end
end
