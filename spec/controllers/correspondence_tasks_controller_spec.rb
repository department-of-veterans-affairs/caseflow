# frozen_string_literal: true

RSpec.describe CorrespondenceTasksController, :all_dbs, type: :controller do
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id) }
  let(:current_user) { create(:user) }
  let(:task_creation_params) { { correspondence_uuid: correspondence.uuid, correspondence_id: correspondence.id } }
  let(:correspondence_with_intake) { create(:correspondence, :with_correspondence_intake_task) }
  let(:assigned_to) { create(:user) }
  let(:correspondence_task) { CorrespondenceTask.first }

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    InboundOpsTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  describe "POST #create_package_action_task" do
    context "RemovePackageTask creation" do
      before do
        task_creation_params.merge!(type: "removePackage", instructions: "please remove task, thanks")
        post :create_package_action_task, params: task_creation_params
      end

      it "creates remove package task successfully" do
        expect(response).to have_http_status(:ok)
        remove_package_task = RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name)
        parent = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
        expect(remove_package_task.appeal).to eq(correspondence)
        expect(remove_package_task.parent_id).to eq(parent.id)
        expect(remove_package_task.instructions).to eq(["please remove task, thanks"])
        expect(remove_package_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(parent.status).to eq(Constants.TASK_STATUSES.on_hold)
      end
    end

    context "SplitPackageTask creation" do
      before do
        task_creation_params.merge!(type: "splitPackage", instructions: "Reason for SplitPackage")
        post :create_package_action_task, params: task_creation_params
      end

      it "creates remove package task successfully" do
        expect(response).to have_http_status(:ok)
        split_package_task = SplitPackageTask.find_by(appeal_id: correspondence.id, type: SplitPackageTask.name)
        parent = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
        expect(split_package_task.appeal).to eq(correspondence)
        expect(split_package_task.parent_id).to eq(parent.id)
        expect(split_package_task.instructions).to eq(["Reason for SplitPackage"])
        expect(split_package_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(parent.status).to eq(Constants.TASK_STATUSES.on_hold)
      end
    end

    context "MergePackageTask creation" do
      before do
        task_creation_params.merge!(type: "mergePackage", instructions: "Reason for MergePackage")
        post :create_package_action_task, params: task_creation_params
      end

      it "creates merge package task successfully" do
        expect(response).to have_http_status(:ok)
        merge_package_task = MergePackageTask.find_by(appeal_id: correspondence.id, type: MergePackageTask.name)
        parent = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
        expect(merge_package_task.appeal).to eq(correspondence)
        expect(merge_package_task.parent_id).to eq(parent.id)
        expect(merge_package_task.instructions).to eq(["Reason for MergePackage"])
        expect(merge_package_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(parent.status).to eq(Constants.TASK_STATUSES.on_hold)
      end
    end
  end

  describe "POST #create_correspondence_intake_task" do
    context "Create correspondece intake task" do
      before do
        task_creation_params[:id] = correspondence.id
        post :create_correspondence_intake_task, params: task_creation_params
      end

      it "creates remove package task successfully" do
        expect(response).to have_http_status(:ok)
        cit = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id, type: CorrespondenceIntakeTask.name)
        review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
        parent = cit.parent
        expect(cit.status).to eq(Constants.TASK_STATUSES.in_progress)
        expect(cit.parent_id).to eq(parent.id)
        expect(review_package_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(review_package_task.parent_id).to eq(parent.id)
      end
    end
  end

  describe "POST #create_return_to_inbound_ops_task" do
    context "Create correspondece return to inbound ops task" do
      before do
        task_creation_params[:id] = correspondence.id
        post :create_return_to_inbound_ops_task, params: task_creation_params
      end

      it "cancels other motion task and creates return to inbound ops task successfully" do
        expect(response).to have_http_status(:ok)
        return_task = ReturnToInboundOpsTask.find_by(appeal_id: correspondence.id, type: ReturnToInboundOpsTask.name)
        other_motion_task = OtherMotionCorrespondenceTask.find_by(
                              appeal_id: correspondence.id, type: OtherMotionCorrespondenceTask.name
                            )
        parent = return_task.parent
        expect(return_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(return_task.parent_id).to eq(parent.id)
        expect(other_motion_task.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(other_motion_task.parent_id).to eq(parent.id)
      end
    end
  end

  describe "PATCH #update assign_to_person" do
    context "Update correspondence task" do
      before do
        task_creation_params.merge!(
          task_id: correspondence_task.id,
          instructions: ["please update task, thanks"],
          assigned_to: assigned_to.css_id
        )
        patch :assign_to_person, params: task_creation_params
      end

      it "creates remove package task successfully" do
        expect(response).to have_http_status(204)
        correspondence_task.reload
        expect(correspondence_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(correspondence_task.assigned_to).to eq(assigned_to)
        expect(correspondence_task.assigned_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end

  describe "PATCH #change_task_type" do
    let(:correspondence_task) do
      create(
        :correspondence_intake_task,
        appeal: correspondence,
        appeal_type: Correspondence.name,
        assigned_to: current_user
      )
    end
    let(:valid_params) do
      {
        task: {
          type: "PoaClarificationColocatedTask",
          instructions: "Updated instructions"
        },
        task_id: correspondence_task.id
      }
    end

    let(:invalid_params) do
      {
        task: {
          type: nil, # Invalid type
          instructions: "Updated instructions"
        },
        task_id: correspondence_task.id
      }
    end

    context "with valid params" do
      it "updates the task with the new type and instructions" do
        patch :change_task_type, params: valid_params

        updated_task = Task.find_by(id: correspondence_task.id)
        expect(updated_task.type).to eq("PoaClarificationColocatedTask")
        expect(updated_task.instructions).to eq(["Updated instructions"])
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid params" do
      it "raises an error and does not update the task" do
        expect do
          patch :change_task_type, params: invalid_params
        end.to raise_error(ActiveRecord::RecordInvalid)

        updated_task = Task.find_by(id: correspondence_task.id)
        expect(updated_task.type).not_to be_nil
        expect(updated_task.type).to eq("CorrespondenceIntakeTask")
      end
    end

    context "with an invalid task ID" do
      it "raises an error" do
        patch :change_task_type, params: { task_id: "invalid_id" }
        expect(response).to have_http_status(404)
      end
    end
  end
end
