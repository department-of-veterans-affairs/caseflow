describe JudgeTask do
  let(:judge) { create(:user) }
  let(:attorney) { create(:user) }
  let!(:staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  context ".create" do
    subject { JudgeTask.create(assigned_to: judge, appeal: create(:appeal)) }

    it "should set the action" do
      expect(subject.action).to eq "assign"
    end
  end

  context ".previous_task" do
    it "should return the only child" do
      parent = create(:ama_judge_task, assigned_to: judge)
      child = create(:ama_attorney_task, assigned_to: attorney, status: "completed", parent: parent)

      expect(parent.previous_task.id).to eq(child.id)
    end

    it "should throw an exception if there are too many children" do
      parent = create(:ama_judge_task, assigned_to: judge)
      create(:ama_attorney_task, assigned_to: attorney, status: "completed", parent: parent)
      create(:ama_attorney_task, assigned_to: attorney, status: "completed", parent: parent)

      expect { parent.previous_task }.to raise_error(Caseflow::Error::TooManyChildTasks)
    end
  end
end
