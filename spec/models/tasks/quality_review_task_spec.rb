# frozen_string_literal: true

describe QualityReviewTask do
  before do
    OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), BvaDispatch.singleton)
  end

  describe ".update!(status: Constants.TASK_STATUSES.completed)" do
    let(:root_task) { FactoryBot.create(:root_task) }

    context "when QualityReviewTask is assigned to the QR organization" do
      let!(:qr_task) { QualityReviewTask.create_from_root_task(root_task) }

      it "should create a task for BVA dispatch and close the current task" do
        expect(root_task.children.select { |t| t.type == BvaDispatchTask.name }.count).to eq(0)
        expect { qr_task.update!(status: Constants.TASK_STATUSES.completed) }.to_not raise_error

        expect(qr_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(root_task.reload.children.select { |t| t.type == BvaDispatchTask.name }.count).to eq(1)
      end
    end

    context "when QualityReviewTask has been assigned to an individual" do
      let!(:appeal) { root_task.appeal }

      let!(:judge) { FactoryBot.create(:user) }
      let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, user: judge) }
      let!(:judge_task) { JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge) }

      let!(:atty) { FactoryBot.create(:user) }
      let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, user: atty) }
      let!(:atty_task_params) { [{ appeal: appeal, parent_id: judge_task.id, assigned_to: atty, assigned_by: judge }] }
      let!(:atty_task) { AttorneyTask.create_many_from_params(atty_task_params, judge).first }

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

      it "should create a task for BVA dispatch and close all QualityReviewTasks" do
        expect(root_task.children.select { |t| t.type == BvaDispatchTask.name }.count).to eq(0)
        expect { qr_person_task.update!(status: Constants.TASK_STATUSES.completed) }.to_not raise_error

        expect(qr_person_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(qr_org_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(root_task.reload.children.select { |t| t.type == BvaDispatchTask.name }.count).to eq(1)
      end
    end
  end
end
