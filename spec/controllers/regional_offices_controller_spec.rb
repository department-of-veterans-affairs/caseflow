RSpec.describe RegionalOfficesController, type: :controller do
  let!(:user) { User.authenticate! }

  context "index" do
    it "returns all regional offices that hold hearings" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["regional_offices"].size).to eq 57
    end
  end
end
