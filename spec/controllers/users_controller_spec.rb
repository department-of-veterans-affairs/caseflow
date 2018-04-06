RSpec.describe UsersController, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["System Admin"])
    FeatureToggle.enable!(:queue_welcome_gate)
  end
  after do
    FeatureToggle.disable!(:queue_welcome_gate)
  end

  describe "GET /users?role=Judge" do
    context "when role is passed" do
      it "should be successful" do
        get :index, params: { role: "Judge" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq 3
      end
    end

    context "when role is not passed" do
      it "should be successful" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body).to eq({})
      end
    end
  end
end
