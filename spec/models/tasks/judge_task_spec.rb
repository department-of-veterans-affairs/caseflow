describe JudgeTask do
  let(:judge) { create(:user) }
  let(:judge2) { create(:user) }
  let(:attorney) { create(:user) }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    create(:staff, :judge_role, sdomainid: judge2.css_id)
    create(:staff, :attorney_role, sdomainid: attorney.css_id)
  end

  describe ".available_actions" do
    let(:user) { judge }
    let(:subject_task) { JudgeAssignTask.create!(assigned_to: judge, appeal: FactoryBot.create(:appeal)) }

    subject { subject_task.available_actions_unwrapper(user) }

    context "the task is not assigned to the current user" do
      let(:user) { judge2 }
      it "should return an empty array" do
        expect(subject).to eq([])
      end
    end

    context "the task is assigned to the current user" do
      context "in the assign phase" do
        it "should return the assignment action" do
          expect(subject).to eq([subject_task.build_action_hash(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h)])
        end

        context "the task was assigned from Quality Review" do
          let(:subject_task) { FactoryBot.create(:ama_judge_quality_review_task, assigned_to: judge) }

          it "should return the assignment and mark complete actions" do
            expect(subject).to eq(
              [
                subject_task.build_action_hash(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h),
                subject_task.build_action_hash(Constants.TASK_ACTIONS.MARK_COMPLETE.to_h)
              ]
            )
          end
        end
      end

      context "in the review phase" do
        let(:subject_task) { FactoryBot.create(:ama_judge_decision_review_task, assigned_to: judge) }

        it "should return the dispatch action" do
          expect(subject).to eq([subject_task.build_action_hash(Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h)])
        end
      end
    end
  end

  describe ".create_from_params" do
    context "creating a JudgeQualityReviewTask from a QualityReviewTask" do
      let(:qr_task) { FactoryBot.create(:qr_task) }
      let(:params) { { assigned_to: judge, appeal: qr_task.appeal, parent_id: qr_task.id } }

      subject { JudgeQualityReviewTask.create_from_params(params, attorney) }

      it "the parent task should change to an 'on hold' status" do
        expect(qr_task.status).to eq("assigned")
        expect(subject.parent.id).to eq(qr_task.id)
        expect(subject.parent.status).to eq("on_hold")
      end
    end
  end

  describe ".udpate_from_params" do
    context "updating a JudgeQualityReviewTask" do
      let(:existing_instructions) { "existing instructions" }
      let(:existing_status) { :assigned }
      let!(:jqr_task) do
        FactoryBot.create(
          :ama_judge_quality_review_task, status: existing_status, instructions: [existing_instructions]
        )
      end
      let(:params) { nil }

      subject { jqr_task.update_from_params(params, nil) }

      context "update includes instruction text" do
        let(:new_instructions) { "new instructions" }
        let(:params) { { instructions: [new_instructions] } }

        it "merges instruction text" do
          subject
          expect(jqr_task.reload.instructions).to eq([existing_instructions, new_instructions])
        end
      end

      context "update has a nil status" do
        let(:params) { { status: nil } }

        it "doesn't change the task's status" do
          subject
          expect(jqr_task.reload.status).to eq(existing_status.to_s)
        end
      end
    end
  end

  describe ".previous_task" do
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

  describe ".when_child_task_completed" do
    let(:attorney_task) { FactoryBot.create(:ama_attorney_task) }

    it "changes the task type" do
      parent = attorney_task.parent
      expect(parent.type).to eq JudgeAssignTask.name
      parent.when_child_task_completed
      expect(parent.type).to eq JudgeDecisionReviewTask.name
    end
  end
end
