# frozen_string_literal: true

RSpec.describe CorrespondenceController, :all_dbs, type: :controller do
  let(:correspondence) { create(:correspondence) }
  let(:veteran) { create(:veteran) }
  let(:valid_params) { { notes: "Updated notes", correspondence_type_id: 12 } }
  let(:new_file_number) { "50000005" }
  let(:current_user) { create(:user)}

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    correspondence.update(veteran: veteran)
  end

  describe "GET #show" do
    before { get :show, params: { id: correspondence.uuid } }

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

  describe "PATCH #update" do
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      correspondence.update(veteran: veteran)
      patch :update, params: {
        id: correspondence.uuid,
        veteran: { file_number: new_file_number },
        correspondence: valid_params
      }
    end

    it "updates the general information" do
      expect(response).to have_http_status(:ok)
      expect(veteran.reload.file_number).to eq(new_file_number)
      expect(correspondence.reload.notes).to eq("Updated notes")
      expect(correspondence.reload.correspondence_type_id).to eq(12)
      expect(correspondence.reload.updated_by_id).to eq(current_user.id)
    end
  end
end
