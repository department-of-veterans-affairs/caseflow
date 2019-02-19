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
              Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h,
              Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end
        it "returns the correct dispatch action" do
          expect(subject).not_to eq(
            [
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
              Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h,
              Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end

        it "returns the correct label" do
          expect(JudgeDecisionReviewTask.new.label).to eq(
            COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
          )
        end

        it "returns the correct additional actions" do
          expect(JudgeDecisionReviewTask.new.additional_available_actions(user)).to eq(
            [Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h,
             Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h]
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
          :ama_judge_quality_review_task,
          assigned_to: judge,
          status: existing_status,
          instructions: [existing_instructions]
        )
      end
      let(:params) { nil }

      subject { jqr_task.update_from_params(params, judge) }

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

  describe ".backfill_taskks" do
    let!(:root_tasks) { [] }

    subject { JudgeTask.backfill_tasks(root_tasks) }

    context "with multiple root tasks" do
      let!(:root_task1) { FactoryBot.create(:root_task) }
      let!(:root_task2) { FactoryBot.create(:root_task) }
      let!(:root_task3) { FactoryBot.create(:root_task) }
      let!(:root_tasks) { [root_task1, root_task2, root_task3] }
      let!(:ihp_task) do
        InformalHearingPresentationTask.create!(
          appeal: root_task1.appeal,
          parent: root_task1,
          status: "assigned",
          assigned_to: create(:vso)
        )
      end
      let!(:ihp_task2) do
        InformalHearingPresentationTask.create!(
          appeal: root_task2.appeal,
          parent: root_task2,
          status: "completed",
          assigned_to: create(:vso)
        )
      end

      it "creates DistributionTasks" do
        expect(DistributionTask.all.count).to eq 0
        subject
        # run subject twice to see if it double creates tasks
        subject
        expect(DistributionTask.all.count).to eq 3
      end

      it "reassigns incomplete ihp tasks so they block distribution" do
        subject

        expect(ihp_task.reload.parent).to eq(DistributionTask.find_by(appeal: ihp_task.appeal))
        expect(ihp_task2.reload.parent).to eq(root_task2)
      end
    end
  end
end
