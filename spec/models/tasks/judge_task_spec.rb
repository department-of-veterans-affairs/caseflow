describe JudgeTask do
  let(:judge) { FactoryBot.create(:user) }
  let(:judge2) { FactoryBot.create(:user) }
  let(:attorney) { FactoryBot.create(:user) }

  before do
    FactoryBot.create(:staff, :judge_role, sdomainid: judge.css_id)
    FactoryBot.create(:staff, :judge_role, sdomainid: judge2.css_id)
    FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
  end

  describe ".available_actions" do
    let(:user) { judge }
    let(:subject_task) do
      FactoryBot.create(:ama_judge_task, assigned_to: judge, appeal: FactoryBot.create(:appeal))
    end

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
          expect(subject).to eq(
            [
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
              Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end

        context "the task was assigned from Quality Review" do
          let(:subject_task) { FactoryBot.create(:ama_judge_quality_review_task, assigned_to: judge) }

          it "should return the assignment and mark complete actions" do
            expect(subject).to eq(
              [
                Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
                Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
                Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
              ].map { |action| subject_task.build_action_hash(action, judge) }
            )
          end
        end
      end

      context "in the review phase" do
        let(:subject_task) do
          FactoryBot.create(:ama_judge_decision_review_task, assigned_to: judge, parent: FactoryBot.create(:root_task))
        end

        it "returns the dispatch action" do
          expect(subject).to eq(
            [
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
              Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h,
              Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end
      end
    end
  end

  describe ".create_from_params" do
    context "creating a JudgeQualityReviewTask from a QualityReviewTask" do
      let(:judge_task) { FactoryBot.create(:ama_judge_task, parent: FactoryBot.create(:root_task), assigned_to: judge) }
      let(:qr_user) { FactoryBot.create(:user) }
      let(:qr_task) { FactoryBot.create(:qr_task, assigned_to: qr_user, parent: judge_task) }
      let(:params) { { assigned_to: judge, appeal: qr_task.appeal, parent_id: qr_task.id } }

      subject { JudgeQualityReviewTask.create_from_params(params, qr_user) }

      before do
        OrganizationsUser.add_user_to_organization(qr_user, QualityReview.singleton)
      end

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
        let(:params) { { instructions: [new_instructions] }.with_indifferent_access }

        it "merges instruction text" do
          subject
          expect(jqr_task.reload.instructions).to eq([existing_instructions, new_instructions])
        end
      end

      context "update has a nil status" do
        let(:params) { { status: nil } }

        it "doesn't change the task's status" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
          expect(jqr_task.reload.status).to eq(existing_status.to_s)
        end
      end
    end
  end

  describe ".previous_task" do
    it "should return the only child" do
      parent = FactoryBot.create(:ama_judge_task, assigned_to: judge)
      child = FactoryBot.create(:ama_attorney_task, assigned_to: attorney, status: "completed", parent: parent)

      expect(parent.previous_task.id).to eq(child.id)
    end

    it "should throw an exception if there are too many children" do
      parent = FactoryBot.create(:ama_judge_task, assigned_to: judge)
      FactoryBot.create(:ama_attorney_task, assigned_to: attorney, status: "completed", parent: parent)
      FactoryBot.create(:ama_attorney_task, assigned_to: attorney, status: "completed", parent: parent)

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
