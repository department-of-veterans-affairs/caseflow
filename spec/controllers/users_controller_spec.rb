RSpec.describe UsersController, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["System Admin"])
  end

  describe "GET /users?role=Judge" do
    context "when role is passed" do
      it "should return a list of judges" do
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

  describe "GET /users?role=Attorney" do
    context "when current user not a judge" do
      it "should not return a list of attorneys" do
        get :index, params: { role: "Attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq 0
      end
    end

    context "when current user a judge" do
      it "should return a list of attorneys" do
        User.create(css_id: "BVARZIEMANN1", station_id: User::BOARD_STATION_ID)
        get :index, params: { role: "Attorney", judge_css_id: "BVARZIEMANN1" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq 3
      end
    end
  end
end
