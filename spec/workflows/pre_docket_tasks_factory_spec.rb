describe PreDocketTasksFactory, :postgres do
  context "PreDocket Appeals" do
    let(:appeal) { create(:appeal) }

    subject { PreDocketTasksFactory.new(appeal).call }

    it "creates a PreDocket Appeal in an on_hold status" do
      expect(PreDocketTask.all.count).to eq 0

      subject

      expect(PreDocketTask.all.count).to eq 1
      expect(PreDocketTask.first.appeal).to eq appeal
      expect(PreDocketTask.first.assigned_to).to eq BvaIntake.singleton
      expect(PreDocketTask.first.parent.is_a?(RootTask)).to eq true
      expect(PreDocketTask.first.status).to eq Constants.TASK_STATUSES.on_hold
    end
  end
end
