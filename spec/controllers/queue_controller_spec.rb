RSpec.describe QueueController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_welcome_gate)
  end

  after do
    FeatureToggle.disable!(:queue_welcome_gate)
  end

  describe "GET queue/judges" do
    it "should be successful" do
      User.authenticate!(roles: ["System Admin"])
      get :judges
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["judges"].size).to eq 3
    end
  end
end
