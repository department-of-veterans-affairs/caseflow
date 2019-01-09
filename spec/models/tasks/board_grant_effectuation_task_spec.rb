describe BoardGrantEffectuationTask do
  let(:task) { create(:board_grant_effectuation_task).becomes(described_class) }

  context "#label" do
    subject { task.label }

    it "has a label of Board Grant" do
      expect(subject).to eq "Board Grant"
    end
  end
end
