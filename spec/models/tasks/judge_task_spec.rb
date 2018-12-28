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
    let(:user) { judge }
    let(:assign_task) { JudgeAssignTask.create!(assigned_to: judge, appeal: FactoryBot.create(:appeal)) }
    let(:review_task) { JudgeReviewTask.create!(assigned_to: judge, appeal: FactoryBot.create(:appeal)) }

    subject { assign_task.available_actions_unwrapper(user) }

    context "when the task is assigned to the current user" do
      context "and we are in the assign phase" do
        it "should return the assignment action" do
          expect(subject).to eq([assign_task.build_action_hash(Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h)])
        end
      end

      context "and we are in the review phase" do
        subject { review_task.available_actions_unwrapper(user) }
        it "should return the dispatch action" do
          expect(subject).to eq([review_task.build_action_hash(Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h)])
        end
      end

      context "and the task was created by quality review and the judge has sent it back to an attorney" do
        let!(:root_task) { FactoryBot.create(:root_task) }
        let!(:appeal) { root_task.appeal }

        let!(:qr_user) { FactoryBot.create(:user) }
        let!(:qr_relationship) { OrganizationsUser.add_user_to_organization(qr_user, QualityReview.singleton) }
        let!(:qr_org_task) { QualityReviewTask.create_from_root_task(root_task) }
        let!(:qr_task_params) do
          [{
            appeal: appeal,
            parent_id: qr_org_task.id,
            assigned_to_id: qr_user.id,
            assigned_to_type: qr_user.class.name,
            assigned_by: qr_user
          }]
        end
        let!(:qr_person_task) { QualityReviewTask.create_many_from_params(qr_task_params, qr_user).first }

        # Quality reviewer returns the case to the judge for corrections.
        let!(:judge_task) { JudgeAssignTask.create!(appeal: appeal, parent: qr_person_task, assigned_to: judge) }

        # Judge sends the case to an attorney for corrections.
        let!(:atty_task_params) do
          [{ appeal: appeal, parent_id: judge_task.id, assigned_to: attorney, assigned_by: judge }]
        end
        let!(:atty_task) { AttorneyTask.create_many_from_params(atty_task_params, judge).first }

        # Attorney is done with corrections and sends case back to judge.
        let!(:complete_atty_task) { atty_task.mark_as_complete! }

        # The judge task changed type so we have to grab it from the database again
        let!(:assign_task) { Task.find(judge_task.id) }

        it "should return the dispatch and mark complete options" do
          options = [
            review_task.build_action_hash(Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h),
            review_task.build_action_hash(Constants.TASK_ACTIONS.MARK_COMPLETE.to_h)
          ]

          expect(subject).to eq(options)
        end
      end
    end

    context "when the task is not assigned to the current user" do
      let(:user) { judge2 }
      it "should return an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  context ".create_from_params" do
    let(:params) { { assigned_to: judge, appeal: FactoryBot.create(:appeal) } }
    subject { JudgeAssignTask.create_from_params(params, attorney) }

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
