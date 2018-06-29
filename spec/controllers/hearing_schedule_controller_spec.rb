RSpec.describe HearingScheduleController, type: :controller do
  context "when user is not authenticated" do
    it "redirects" do
      get :index
      expect(response.status).to eq 302
    end
  end

  context "when user does not have correct permissions" do
    before do
      User.authenticate!(roles: ["Wrong Role"])
    end
    it "redirects" do
      get :index
      expect(response.status).to eq 302
    end
  end

  context "when user has correct permissions" do
    before do
      User.authenticate!(roles: ["Build HearSched"])
    end
    it "returns a successful response" do
      get :index
      expect(response.status).to eq 200
    end
  end
end
