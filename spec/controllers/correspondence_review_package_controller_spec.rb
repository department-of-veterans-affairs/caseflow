# frozen_string_literal: true

require "pry"
RSpec.describe CorrespondenceReviewPackageController, :all_dbs, type: :controller do
  let(:veteran) { create(:veteran) }
  let(:correspondence_type) { create(:correspondence_type) }
  let(:mail_team_supervisor_user) { create(:inbound_ops_team_supervisor) }
  let(:mail_team_supervisor_org) { InboundOpsTeam.singleton }
  let(:correspondence) { create(:correspondence, veteran: veteran) }
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

  describe "GET #review_package" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :review_package, params: { correspondence_uuid: correspondence.uuid }, format: :json
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PUT #update_cmp" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      put :update_cmp, params: {
        correspondence_uuid: correspondence.uuid,
        VADORDate: Time.zone.now
      }
    end

    it "returns 200 status" do
      expect(response.status).to eq 200
    end
  end

  describe "GET #review_package" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :review_package, params: { correspondence_uuid: correspondence.uuid }, format: :json
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

  describe "GET #review_package" do
    it "returns an unauthorized response" do
      get :review_package, params: { correspondence_uuid: correspondence.uuid }, format: :json
      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "returns a success response when current user is part of InboundOpsTeam" do
      InboundOpsTeam.singleton.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
      correspondence.save(validate: false)
      get :review_package, params: { correspondence_uuid: correspondence.uuid }, format: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    let(:veteran) { create(:veteran, file_number: new_file_number) }
    before do
      InboundOpsTeam.singleton.add_user(current_user)
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
    end

    it "returns an error message if something goes wrong" do
      allow_any_instance_of(CorrespondenceReviewPackageController)
        .to receive(:update_veteran_on_correspondence).and_return(false)
      patch :update, params: {
        correspondence_uuid: correspondence.uuid,
        veteran: { file_number: new_file_number },
        correspondence: valid_params
      }

      error = JSON.parse(response.body, symbolize_names: true)[:error]
      expect(response.status).to eq 422
      expect(error).to eq("Please enter a valid Veteran ID")
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
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      allow(ExternalApi::ClaimEvidenceService).to receive(:document_types).and_return(document_types_response)
    end

    it "returns an array of hashes with id and name" do
      get :document_type_correspondence
      body = JSON.parse(response.body, symbolize_names: true)

      expect(body[:data]).to eq(
        [
          { id: 150, name: "VA Form 21-8056" },
          { id: 152, name: "VA Form 21-8358" }
        ]
      )
    end
  end
end
