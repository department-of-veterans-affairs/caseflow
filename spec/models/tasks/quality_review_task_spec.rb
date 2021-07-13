# frozen_string_literal: true

describe QualityReviewTask, :all_dbs do
  let(:root_task) { create(:root_task) }
  let(:qr_task) { QualityReviewTask.create_from_root_task(root_task) }

  before do
    BvaDispatch.singleton.add_user(create(:user))
  end

  describe ".update!(status: Constants.TASK_STATUSES.completed)" do
    context "when QualityReviewTask is assigned to the QR organization" do
      it "should create a task for BVA dispatch and close the current task" do
        expect(root_task.children.count { |t| t.type == BvaDispatchTask.name }).to eq(0)
        expect { qr_task.update!(status: Constants.TASK_STATUSES.completed) }.to_not raise_error

        expect(qr_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(root_task.reload.children.count { |t| t.type == BvaDispatchTask.name }).to eq(1)
      end
    end

    context "when QualityReviewTask has been assigned to an individual" do
      let!(:appeal) { root_task.appeal }

      let!(:judge) { create(:user) }
      let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }
      let!(:judge_task) { JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge) }

      let!(:atty) { create(:user) }
      let!(:vacols_atty) { create(:staff, :attorney_role, user: atty) }
      let!(:atty_task_params) { [{ appeal: appeal, parent_id: judge_task.id, assigned_to: atty, assigned_by: judge }] }
      let!(:atty_task) { AttorneyTask.create_many_from_params(atty_task_params, judge).first }

      let!(:qr_user) { create(:user) }
      let!(:qr_relationship) { QualityReview.singleton.add_user(qr_user) }
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
        expect(root_task.children.count { |t| t.type == BvaDispatchTask.name }).to eq(0)
        expect { qr_person_task.update!(status: Constants.TASK_STATUSES.completed) }.to_not raise_error

        expect(qr_person_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(qr_org_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(root_task.reload.children.count { |t| t.type == BvaDispatchTask.name }).to eq(1)
      end
    end
  end

  describe ".update!(status: Constants.TASK_STATUSES.cancelled)" do
    it "should create a task for BVA dispatch" do
      qr_task.update!(status: Constants.TASK_STATUSES.cancelled)
      expect(qr_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      expect(root_task.reload.children.count { |t| t.type == BvaDispatchTask.name }).to eq(1)
    end
  end

  describe "completing a child Task" do
    let!(:child_task) do
      Task.create!(type: Task.name, appeal: qr_task.appeal, parent: qr_task, assigned_to: create(:user))
    end
    it "sets the status of the parent QualityReviewTask to assigned" do
      expect(qr_task.status).to eq(Constants.TASK_STATUSES.on_hold)
      child_task.update!(status: Constants.TASK_STATUSES.completed)
      expect(qr_task.status).to eq(Constants.TASK_STATUSES.assigned)
    end
  end

  describe ".create_from_root_task" do
    context "when case belongs to an unrecognized appellant" do
      let(:claimant) { create(:claimant, :with_unrecognized_appellant_detail, type: "OtherClaimant") }
      let(:appeal) { create(:appeal, claimants: [claimant]) }
      let(:root_task) { create(:root_task, appeal: appeal) }

      subject { QualityReviewTask.create_from_root_task(root_task) }

      it "should raise an error" do
        expect { subject }.to raise_error(NotImplementedError)
      end

      context "when allow_unrecognized_appellant_dispatch toggle is enabled" do
        before { FeatureToggle.enable!(:allow_unrecognized_appellant_dispatch) }
        after { FeatureToggle.disable!(:allow_unrecognized_appellant_dispatch) }

        it "should not raise an error" do
          subject
        end
      end
    end
  end
end
