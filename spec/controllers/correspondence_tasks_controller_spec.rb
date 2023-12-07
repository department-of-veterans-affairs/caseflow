# frozen_string_literal: true

RSpec.describe CorrespondenceTasksController, :all_dbs, type: :controller do
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id) }
  let(:current_user) { create(:user) }

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  describe "POST #create_package_action_task" do
    before do
      post :create_package_action_task, params: {
        correspondence_uuid: correspondence.uuid,
        correspondence_id: correspondence.id,
        type: "removePackage",
        instructions: ["please remove task, thanks"]
      }
    end

    it "creates remove package task successfully" do
      expect(response).to have_http_status(:ok)
      remove_package_task = RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name)
      parent = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
      expect(remove_package_task.appeal).to eq(correspondence)
      expect(remove_package_task.parent_id).to eq(parent.id)
      expect(remove_package_task.status).to eq(Constants.TASK_STATUSES.assigned)
      expect(parent.status).to eq(Constants.TASK_STATUSES.on_hold)
    end
  end
end
