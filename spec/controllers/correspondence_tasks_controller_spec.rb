# frozen_string_literal: true

RSpec.describe CorrespondenceTasksController, :all_dbs, type: :controller do
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id) }
  let(:current_user) { create(:user) }
  let(:task_creation_params) { { correspondence_uuid: correspondence.uuid, correspondence_id: correspondence.id } }

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  describe "POST #create_package_action_task" do
    context "RemovePackageTask creation" do
      before do
        task_creation_params.merge!(type: "removePackage", instructions: ["please remove task, thanks"])
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
        task_creation_params.merge!(type: "splitPackage", instructions: ["Reason for SplitPackage"])
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
        task_creation_params.merge!(type: "mergePackage", instructions: ["Reason for MergePackage"])
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
        expect(cit.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(cit.parent_id).to eq(parent.id)
        expect(review_package_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(review_package_task.parent_id).to eq(parent.id)
      end
    end
  end

  describe "POST #remove_package" do
    context "Delete correspondence package from Caseflow" do
      before do
        task_creation_params.merge!(type: "removePackage", instructions: ["please remove task, thanks"])
        post :create_package_action_task, params: task_creation_params
        expect(response).to have_http_status(:ok)
        task_creation_params[:id] = correspondence.id
        post :remove_package, params: task_creation_params
      end

      it "creates remove package task successfully" do
        remove_package_task = RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name)
        expect(remove_package_task.status).to eq(Constants.TASK_STATUSES.cancelled)
        review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
        expect(review_package_task.status).to eq(Constants.TASK_STATUSES.cancelled)
      end
    end
  end

  describe "POST #reject_package" do
    context "Reject Delete correspondence package from Caseflow" do
      before do
        task_creation_params.merge!(type: "removePackage", instructions: ["please remove task, thanks"])
        post :create_package_action_task, params: task_creation_params
        expect(response).to have_http_status(:ok)
        task_creation_params[:id] = correspondence.id
        post :completed_package, params: task_creation_params
      end

      it "reject remove package task successfully" do
        remove_package_task = RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name)
        expect(remove_package_task.status).to eq(Constants.TASK_STATUSES.completed)
        review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
        expect(review_package_task.status).to eq(Constants.TASK_STATUSES.in_progress)
      end
    end
  end
end
