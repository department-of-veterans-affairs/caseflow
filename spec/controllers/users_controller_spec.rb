RSpec.describe UsersController, type: :controller do
  before do
    Fakes::Initializer.load!
  end

  describe "GET /users?role=Judge" do
    it "should be successful" do
      FeatureToggle.enable!(:queue_welcome_gate)
      User.authenticate!(roles: ["System Admin"])
      get :index, role: "Judge"
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["judges"].size).to eq 3
      FeatureToggle.disable!(:queue_welcome_gate)
    end
  end
end
