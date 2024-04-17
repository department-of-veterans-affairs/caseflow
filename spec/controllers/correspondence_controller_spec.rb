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

  describe "GET #correspondence_team" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    it "returns a successful response" do
      get :correspondence_team, params: { taskId: esw_tasks.first[:task_id],
                                          veteranName: "Bob%20Smithwatsica",
                                          userAction: "approve",
                                          user: current_user.css_id,
                                          decisionReason: "",
                                          operation: "remove" }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully removed a mail package for Bob Smithwatsica")
      expect(controller.view_assigns["response_message"]).to eq("The package has been removed from Caseflow and must be manually uploaded again\n     from the Centralized Mail Portal, if it needs to be processed.")
    end

    it "returns a failure response" do
      allow(controller).to receive(:update_remove_task).and_raise(StandardError)
      get :correspondence_team, params: { taskId: esw_tasks.first[:task_id],
                                          veteranName: "Bob%20Smithwatsica",
                                          userAction: "approve",
                                          user: current_user.css_id,
                                          decisionReason: "",
                                          operation: "remove" }

      expect(controller.view_assigns["response_header"]).to eq("Package request for Bob Smithwatsica could not be approved")
      expect(controller.view_assigns["response_message"]).to eq("Please try again at a later time or contact the Help Desk.")
    end

    it "returns cancel intake response" do
      get :correspondence_team, params: { veteranName: "Bob%20Smithwatsica",
                                          userAction: "cancel_intake",
                                          user: current_user.css_id,
                                          id: correspondence.id }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully cancelled the intake form")
      expect(controller.view_assigns["response_message"]).to eq("Bob Smithwatsica's correspondence (ID: #{correspondence.id}) has been returned to the supervisor's queue for assignment.")
    end

    it "returns intake continue later response" do
      get :correspondence_team, params: { veteranName: "Bob%20Smithwatsica",
                                          userAction: "continue_later",
                                          user: current_user.css_id,
                                          id: correspondence.id }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully saved the intake form")
      expect(controller.view_assigns["response_message"]).to eq("You can continue from step three of the intake form for Bob Smithwatsica's correspondence (ID: #{correspondence.id}) at a later date.")
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
end
