RSpec.describe Hearings::WorksheetsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let(:appeal) { Generators::Appeal.create(vacols_record: :ready_to_certify) }
  let(:hearing) do
    Generators::Hearing.create(
      appellant_first_name: "AppellantFirstName",
      appellant_last_name: "AppellantLastName",
      veteran_first_name: "VeteranFirstName",
      veteran_last_name: "VeteranLastName",
      type: "video",
      master_record: false,
      appeal: appeal
    )
  end

  describe "SHOW worksheet" do
    it "returns data with success" do
      get :show, params: { hearing_id: hearing.id }, format: "json"
      response_hearing = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(response_hearing[:veteran_sex]).to eq nil
      expect(response_hearing[:veteran_age]).to eq nil
      expect(response_hearing["id"]).to eq hearing.id
      expect(response_hearing["vacols_id"]).to eq hearing.vacols_id
    end

    it "should fail with 404 error message" do
      get :show, params: { hearing_id: "12121" }, format: "json"
      expect(response.status).to eq 404
      expect(response.body).to eq "{\"errors\":[{\"message\":\"Couldn't find Hearing with 'id'=12121\",\"code\":1000}]}"
    end
  end
end
