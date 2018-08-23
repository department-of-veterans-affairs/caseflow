describe JudgeTask do
  let(:judge) { create(:user) }
  let!(:staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  context ".create" do
    subject { JudgeTask.create(assigned_to: judge, appeal: create(:appeal)) }

    it "should set the action" do
      expect(subject.action).to eq "assign"
    end
  end
end
