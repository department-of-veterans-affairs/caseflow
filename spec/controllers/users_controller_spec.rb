RSpec.describe UsersController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["System Admin"]) }
  let!(:staff) { create(:staff, :attorney_judge_role, user: user) }

  describe "GET /users?role=Judge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }

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
    context "when judge ID is passed" do
      let!(:judge) { User.create(css_id: "BVARZIEMANN1", station_id: User::BOARD_STATION_ID) }

      it "should return a list of attorneys associated with the judge" do
        get :index, params: { role: "Attorney", judge_css_id: judge.css_id }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq 3
      end
    end

    context "when judge ID is not passed" do
      let!(:staff_attorney) { create(:staff, :attorney_role, sdomainid: "BVACFRANECKI1") }
      let!(:judges) { create_list(:staff, 2, :judge_role) }

      it "should return a list of all attorneys" do
        get :index, params: { role: "Attorney" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        # four regular attorneys and one attorney acting as a judge
        expect(response_body["attorneys"].size).to eq 4
        attorney = response_body["attorneys"].select { |e| e["css_id"] == staff_attorney.sdomainid }[0]
        expect(attorney["judge_css_id"]).to eq "BVARZIEMANN1"
      end
    end
  end

  describe "GET /users?role=HearingCoordinator" do
    let!(:coordinators) { create_list(:staff, 3, :hearing_coordinator) }

    context "when role is passed" do
      it "should return a list of hearing coordinators" do
        get :index, params: { role: "HearingCoordinator" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["coordinators"].size).to eq 3
      end
    end
  end

  describe "GET /users?role=HearingJudge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }

    context "when role is passed" do
      it "should return a list of judges" do
        get :index, params: { role: "HearingJudge" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq 2
      end
    end
  end
end
