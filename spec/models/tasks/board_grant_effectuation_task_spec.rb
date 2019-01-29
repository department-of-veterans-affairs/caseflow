describe BoardGrantEffectuationTask do
  let(:task_status) { "assigned" }
  let(:task) { create(:board_grant_effectuation_task, status: task_status).becomes(described_class) }

  context "#label" do
    subject { task.label }

    it "has a label of Board Grant" do
      expect(subject).to eq "Board Grant"
    end
  end

  describe "#complete_with_payload!" do
    subject { task.complete_with_payload!(nil, nil) }

    context "assigned task" do
      it "can be completed" do
        expect(subject).to eq true
        task.reload
        expect(task.status).to eq "completed"
      end
    end

    context "completed task" do
      let(:task_status) { "completed" }

      it "cannot be completed again" do
        expect(subject).to eq false
      end
    end
  end
end
