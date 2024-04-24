# frozen_string_literal: true

RSpec.describe CorrespondenceIntakeController, :all_dbs, type: :controller do
  let(:veteran) { create(:veteran) }
  let(:correspondence_type) { create(:correspondence_type) }
  let(:correspondence) { create(:correspondence, veteran: veteran) }

  let(:related_correspondence_uuids) do
    (1..3).map { create(:correspondence) }.pluck(:uuid)
  end
  let(:esw_tasks) do
    (1..3).map do
      appeal = create(:appeal)
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      {
        task_id: EvidenceSubmissionWindowTask.find_by(appeal: appeal).id,
        waive_reason: "This is a waive reason."
      }
    end
  end
  let(:current_user) { create(:user) }
  let!(:parent_task) { create(:correspondence_intake_task, appeal: correspondence, assigned_to: current_user) }

  let(:mock_doc_uploader) { instance_double(CorrespondenceDocumentsEfolderUploader) }

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    correspondence.update(veteran: veteran)

    allow(CorrespondenceDocumentsEfolderUploader).to receive(:new).and_return(mock_doc_uploader)
    allow(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence).and_return(true)
  end

  describe "GET #intake" do
    it "returns 200 status" do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      3.times { create(:correspondence, veteran: veteran) }
      get :intake, params: { correspondence_uuid: correspondence.uuid }

      expect(response.status).to eq 200
    end
  end

  describe "POST #process_intake" do
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      correspondence.update(veteran: veteran)
      appeal_ids = esw_tasks.map { |task| Task.find(task[:task_id]).appeal.id }
      post :process_intake, params: {
        correspondence_uuid: correspondence.uuid,
        related_correspondence_uuids: related_correspondence_uuids,
        waived_evidence_submission_window_tasks: esw_tasks,
        related_appeal_ids: appeal_ids
      }
    end
    it "responds with created status" do
      expect(response).to have_http_status(:created)
    end

    it "relates the correspondence to related correpondences" do
      rcs = related_correspondence_uuids.map do |uuid|
        Correspondence.find_by(uuid: uuid)
      end
      expect(correspondence.related_correspondences).to eq(rcs)

      rcs.each do |corr|
        expect(corr.related_correspondences).to eq([correspondence])
      end
    end

    it "completes evidence window submission tasks" do
      esw_tasks.each do |esw_task|
        task = Task.find(esw_task[:task_id])
        expect(task.status).to eq("completed")
        expect(task.instructions.include?("This is a waive reason.")).to eq(true)
        expect(task.appeal.correspondences).to eq([correspondence])
      end
    end
  end

  describe "PATCH #intake_update" do
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    it "returns 200 - happy path" do
      patch :intake_update, params: { correspondence_uuid: correspondence.uuid }

      expect(response.status).to eq 200
    end

    it "cancels the task tree and returns the correspondence" do
      # initial state
      task_statuses = correspondence.tasks.map(&:status)
      expect(task_statuses.any?(Constants.TASK_STATUSES.cancelled)).to eq false

      patch :intake_update, params: { correspondence_uuid: correspondence.uuid }

      # updated state after the request
      task_statuses = correspondence.tasks.map(&:status)
      expect(task_statuses.all?(Constants.TASK_STATUSES.cancelled)).to eq true

      body = JSON.parse(response.body, symbolize_names: true)

      expect(body[:correspondence]).to be_a(Hash)
      expect(body[:correspondence].empty?).to eq false
    end

    it "returns bad request code if error - sad path" do
      allow_any_instance_of(Correspondence)
        .to receive(:cancel_task_tree_for_appeal_intake).and_raise(StandardError)

      patch :intake_update, params: { correspondence_uuid: correspondence.uuid }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST #process_intake sad path" do
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      correspondence.update(veteran: veteran)
    end

    it "Rolls back db changes if there is an error" do
      post :process_intake, params: {
        correspondence_uuid: correspondence.uuid,
        related_correspondence_uuids: (related_correspondence_uuids + [3])
      }
      expect(correspondence.related_correspondences.empty?).to be(true)
    end

    it "gives a 400 status if there is an error" do
      post :process_intake, params: {
        correspondence_uuid: correspondence.uuid,
        related_correspondence_uuids: (related_correspondence_uuids + [3])
      }
      expect(response.status).to eq(400)
    end
  end
end
