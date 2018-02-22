describe QueueRepository do
  before do
    Timecop.freeze(Time.utc(2017, 10, 4))
    Time.zone = "America/Chicago"
  end

  context ".find_decass_record" do
    subject { QueueRepository.find_decass_record(task_id) }

    context "when task id is valid and decass record is found" do
      before do
        allow(QueueRepository).to receive(:decass_by_vacols_id_and_date_assigned).and_return(OpenStruct.new)
      end
      let(:task_id) { "123456-2014-02-03" }
      it { is_expected.to_not be nil }
    end

    context "when task id is valid and decass record is not found" do
      before do
        allow(QueueRepository).to receive(:decass_by_vacols_id_and_date_assigned).and_return(nil)
      end
      let(:task_id) { "123456-2014-02-03" }
      it "raises QueueRepository::ReassignCaseToJudgeError" do
        expect { subject }.to raise_error(QueueRepository::ReassignCaseToJudgeError)
      end
    end

    context "when task id is not valid" do
      let(:task_id) { "123456" }
      it "raises QueueRepository::ReassignCaseToJudgeError" do
        expect { subject }.to raise_error(QueueRepository::ReassignCaseToJudgeError)
      end
    end
  end

  context ".filter_duplicate_tasks" do
    subject { QueueRepository.filter_duplicate_tasks(tasks) }

    let(:tasks) do
      [
        OpenStruct.new(vacols_id: "123C", date_assigned: 3.days.ago),
        OpenStruct.new(vacols_id: "123B", date_assigned: 5.days.ago),
        OpenStruct.new(vacols_id: "123C", date_assigned: 2.days.ago),
        OpenStruct.new(vacols_id: "123C", date_assigned: 9.days.ago),
        OpenStruct.new(vacols_id: "123A", date_assigned: 9.days.ago)
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
