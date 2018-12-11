RSpec.describe UsersController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["System Admin"]) }
  let!(:staff) { create(:staff, :attorney_judge_role, user: user) }

  describe "GET /users?role=Judge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }
    let!(:attorneys) { create_list(:staff, 2, :attorney_role) }

    context "when role is passed" do
      it "should return a list of only judges" do
        get :index, params: { role: "Judge" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq 3
      end
    end

    context "when role is not passed" do
      it "should return an empty hash" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body).to eq({})
      end
    end
  end

  describe "GET /users?role=Attorney" do
    let(:judge) { Judge.new(FactoryBot.create(:user)) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
    let(:team_member_count) { 3 }
    let(:solo_count) { 3 }
    let(:team_attorneys) { FactoryBot.create_list(:user, team_member_count) }
    let(:solo_attorneys) { FactoryBot.create_list(:user, solo_count) }

    before do
      [team_attorneys, solo_attorneys].flatten.each do |attorney|
        create(:staff, :attorney_role, user: attorney)
      end

      team_attorneys.each do |attorney|
        OrganizationsUser.add_user_to_organization(attorney, judge_team)
      end
    end

    context "when judge ID is passed" do
      subject { get :index, params: { role: "Attorney", judge_css_id: judge.user.css_id } }

      it "should return a list of attorneys on the judge's team" do
        subject
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq team_member_count
      end
    end

    context "when judge ID is not passed" do
      subject { get :index, params: { role: "Attorney" } }

      it "should return a list of all attorneys" do
        subject
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq team_member_count + solo_count + 1
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
        expect(response_body["hearingJudges"].size).to eq 3
      end
    end
  end
end
