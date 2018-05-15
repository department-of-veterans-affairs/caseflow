RSpec.describe Hearings::WorksheetsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }

  describe "GET worksheet" do
    it "should be fail" do
      get :show, params: { hearing_id: "12121" }, format: "json"
      expect(response.status).to eq 404
      expect(response.body).to eq "{\"errors\":[{\"message\":\"Couldn't find Hearing with 'id'=12121\",\"code\":1000}]}"
    end
  end
end
