describe AttorneyTask do
  let(:attorney) { create(:user) }
  let(:judge) { create(:user) }
  let!(:staff1) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let!(:staff2) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:parent) { create(:ama_judge_task, assigned_by: judge) }

  context ".create" do
    subject { AttorneyTask.create(assigned_to: attorney, assigned_by: judge, appeal: create(:appeal), parent: parent) }

    it "should validate number of children" do
      expect(subject.valid?).to eq true
      record = AttorneyTask.create!(
        assigned_to: attorney,
        assigned_by: judge,
        appeal: create(:appeal),
        parent: subject.parent
      )
      expect(record.valid?).to eq false
      expect(record.errors.messages[:parent].first).to eq "has too many children"
    end
  end
end
