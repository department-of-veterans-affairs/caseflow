describe JudgeTask do
  let(:judge) { create(:user) }
  let(:judge2) { create(:user) }
  let(:attorney) { create(:user) }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    create(:staff, :judge_role, sdomainid: judge2.css_id)
    create(:staff, :attorney_role, sdomainid: attorney.css_id)
  end

  context ".available_actions" do
    let(:action) { nil }
    let(:user) { judge }
    let(:task) { JudgeTask.create!(assigned_to: judge, appeal: FactoryBot.create(:appeal), action: action) }
    subject { task.available_actions_unwrapper(user) }

    context "when the task is assigned to the current user" do
      context "and we are in the assign phase" do
        let(:action) { "assign" }
        it "should return the assignment action" do
          expect(subject).to eq([task.build_action_hash(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h)])
        end
      end

      context "and we are in the review phase" do
        let(:action) { "review" }
        it "should return the dispatch action" do
          expect(subject).to eq([task.build_action_hash(Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h)])
        end
      end
    end

    context "when the task is not assigned to the current user" do
      let(:user) { judge2 }
      let(:action) { "review" }
      it "should return an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  context ".create_from_params" do
    let(:params) { { assigned_to: judge, appeal: FactoryBot.create(:appeal) } }
    subject { JudgeTask.create_from_params(params, attorney) }

    it "should set the action" do
      expect(subject.action).to eq(nil)
      expect(subject.type).to eq JudgeAssignTask.name
    end

    it "should set the action" do
      expect(subject.action).to eq nil
      expect(subject.type).to eq JudgeAssignTask.name
    end

    context "when creating a JudgeTask from a QualityReviewTask" do
      let(:qr_task) { FactoryBot.create(:qr_task) }
      let(:params) { { assigned_to: judge, appeal: qr_task.appeal, parent_id: qr_task.id } }

      it "QualityReviewTask should be parent of JudgeTask" do
        expect(subject.parent.id).to eq(qr_task.id)
      end
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

  context ".when_child_task_completed" do
    let(:attorney_task) { FactoryBot.create(:ama_attorney_task) }

    it "should change the task type" do
      parent = attorney_task.parent
      expect(parent.type).to eq JudgeAssignTask.name
      parent.when_child_task_completed
      expect(parent.type).to eq JudgeReviewTask.name
    end
  end
end
