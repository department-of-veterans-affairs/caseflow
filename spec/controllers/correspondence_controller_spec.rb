# frozen_string_literal: true

RSpec.describe CorrespondenceController, :all_dbs, type: :controller do
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
  let(:veteran) { create(:veteran) }
  let(:valid_params) { { notes: "Updated notes", correspondence_type_id: correspondence_type.id } }
  let(:new_file_number) { "50000005" }
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

  describe "GET #show" do
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :show, params: { correspondence_uuid: correspondence.uuid }
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns the general information" do
      json_response = JSON.parse(response.body)
      correspondence_data = json_response["correspondence"]
      general_info = json_response["general_information"]
      expect(correspondence_data["notes"]).to eq(correspondence.notes)
      expect(general_info["file_number"]).to eq(veteran.file_number)
      expect(general_info["correspondence_type_id"]).to eq(correspondence.correspondence_type_id)
    end
  end

  describe "GET #show" do
    it "returns an unauthorized response" do
      get :show, params: { correspondence_uuid: correspondence.uuid }
      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "returns a success response when current user is part of InboundOpsTeam" do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :show, params: { correspondence_uuid: correspondence.uuid }
      expect(response).to have_http_status(:ok)
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

  describe "PATCH #update" do
    let(:veteran) { create(:veteran, file_number: new_file_number) }
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      correspondence.update(veteran: veteran)
      patch :update, params: {
        correspondence_uuid: correspondence.uuid,
        veteran: { file_number: new_file_number },
        correspondence: valid_params
      }
    end

    it "updates the general information" do
      expect(response).to have_http_status(:ok)
      expect(veteran.reload.file_number).to eq(new_file_number)
      expect(correspondence.reload.notes).to eq("Updated notes")
      expect(correspondence.reload.correspondence_type_id).to eq(correspondence_type.id)
      expect(correspondence.reload.updated_by_id).to eq(current_user.id)
    end
  end

  describe "document_type_correspondence" do
    let(:document_types_response) do
      [
        {
          "id" => 150,
          "createDateTime" => "2011-12-09",
          "modifiedDateTime" => "2023-07-30T21:04:14",
          "name" => "L141",
          "description" => "VA Form 21-8056",
          "isUserUploadable" => true,
          "is526" => false,
          "documentCategory" => {
            "id" => 70,
            "createDateTime" => "2011-12-09",
            "modifiedDateTime" => "2014-04-21T11:49:07",
            "description" => "Correspondence",
            "subDescription" => "Miscellaneous"
          }
        },
        {
          "id" => 152,
          "createDateTime" => "2011-12-09",
          "modifiedDateTime" => "2023-07-30T21:04:14",
          "name" => "L143",
          "description" => "VA Form 21-8358",
          "isUserUploadable" => true,
          "is526" => false,
          "documentCategory" => {
            "id" => 70,
            "createDateTime" => "2011-12-09",
            "modifiedDateTime" => "2014-04-21T11:49:07",
            "description" => "Correspondence",
            "subDescription" => "Miscellaneous"
          }
        }
      ]
    end

    before do
      allow(ExternalApi::ClaimEvidenceService).to receive(:document_types).and_return(document_types_response)
    end

    it "returns an array of hashes with id and name" do
      result = controller.send(:vbms_document_types)
      expect(result).to eq(
        [
          { id: 150, name: "VA Form 21-8056" },
          { id: 152, name: "VA Form 21-8358" }
        ]
      )
    end
  end

  describe "GET #auto_assign_correpsondences" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    context "when there is no existing batch assignment attempt" do
      it "creates batch auto assignment attempt and returns the id" do
        expect { get :auto_assign_correspondences }.to change(BatchAutoAssignmentAttempt, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["batch_auto_assignment_attempt_id"]).to eq(BatchAutoAssignmentAttempt.last.id)
      end
    end

    context "when there is an existing batch assignment attempt" do
      it "does not create batch auto assignment attempt and returns the id" do
        BatchAutoAssignmentAttempt.create!(
          user: current_user,
          status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started
        )
        expect { get :auto_assign_correspondences }.to_not change(BatchAutoAssignmentAttempt, :count)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["batch_auto_assignment_attempt_id"]).to eq(BatchAutoAssignmentAttempt.last.id)
      end
    end
  end

  describe "POST #auto_assign_status" do
    let(:error_baaa) do
      create(:batch_auto_assignment_attempt, :max_capacity_error, :packages_assigned, user_id: current_user.id)
    end

    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    it "returns status details" do
      get :auto_assign_status, params: { batch_auto_assignment_attempt_id: error_baaa.id }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq(error_baaa.status)
      expect(body["number_assigned"]).to eq(error_baaa.num_packages_assigned)
      expect(body["error_message"]).to eq(error_baaa.error_info)
    end
  end
end
