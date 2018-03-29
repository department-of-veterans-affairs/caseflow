describe QueueRepository do
  context ".filter_duplicate_tasks" do
    subject { QueueRepository.filter_duplicate_tasks(tasks) }

    let(:tasks) do
      [
        OpenStruct.new(vacols_id: "123C", created_at: 3.days.ago),
        OpenStruct.new(vacols_id: "123B", created_at: 5.days.ago),
        OpenStruct.new(vacols_id: "123C", created_at: 2.days.ago),
        OpenStruct.new(vacols_id: "123C", created_at: 9.days.ago),
        OpenStruct.new(vacols_id: "123A", created_at: 9.days.ago)
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
