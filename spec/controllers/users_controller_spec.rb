# frozen_string_literal: true

RSpec.describe UsersController, :all_dbs, type: :controller do
  let!(:authenticated_user) { User.authenticate!(roles: ["System Admin"]) }
  let!(:staff) { create(:staff, :attorney_judge_role, user: authenticated_user) }

  describe "GET /users?role=Judge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }
    let!(:attorneys) { create_list(:staff, 2, :attorney_role) }

    context "when role is passed" do
      it "should return a list of only judges" do
        get :index, params: { role: "Judge" }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq(3)
      end
    end

    context "when role is not passed" do
      it "should return an empty hash" do
        get :index
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body).to eq({})
      end
    end
  end

  describe "GET /users?role=Attorney" do
    let(:judge) { Judge.new(create(:user)) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
    let(:team_member_count) { 3 }
    let(:solo_count) { 3 }
    let(:team_attorneys) { create_list(:user, team_member_count) }
    let(:solo_attorneys) { create_list(:user, solo_count) }

    before do
      create(:staff, :judge_role, user: judge.user)

      [team_attorneys, solo_attorneys].flatten.each do |attorney|
        create(:staff, :attorney_role, user: attorney)
      end

      team_attorneys.each do |attorney|
        judge_team.add_user(attorney)
      end
    end

    context "when judge ID is passed" do
      subject { get :index, params: { role: "Attorney", judge_id: judge.user.id } }

      it "should return a list of attorneys on the judge's team" do
        subject
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"]["data"].size).to eq(team_member_count)
      end
    end

    context "when judge ID is not passed" do
      subject { get :index, params: { role: "Attorney" } }

      it "should return a list of all attorneys, excluding judges" do
        subject
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq(team_member_count + solo_count + 1)
      end
    end
  end

  describe "GET /users?role=HearingCoordinator" do
    let!(:users) { create_list(:user, 3) }
    before do
      users.each do |user|
        HearingsManagement.singleton.add_user(user)
      end
    end

    context "when role is passed" do
      it "should return a list of hearing coordinators" do
        get :index, params: { role: "HearingCoordinator" }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["coordinators"].size).to eq(3)
      end
    end
  end

  describe "GET /users?role=Judge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }

    context "when role is passed" do
      it "should return a list of judges" do
        get :index, params: { role: "Judge" }
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq(3)
      end
    end
  end

  describe "GET /users?role=non_judges" do
    before { judge_team_count.times { JudgeTeam.create_for_judge(create(:user)) } }

    context "when there are no judge teams" do
      let!(:users) { create_list(:user, 8) }
      let(:judge_team_count) { 0 }

      # Add one for the current user who was created outside the scope of this test.
      let(:user_count) { users.count + 1 }

      it "returns all of the users in the database" do
        get(:index, params: { role: "non_judges" })

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["non_judges"]["data"].size).to eq(user_count)
      end
    end
  end

  describe "GET /users?css_id=<css_id>" do
    let!(:users) { create_list(:user, 8) }
    let(:org) { create(:organization) }
    let(:body) { JSON.parse(response.body) }

    subject { get(:index, params: { css_id: css_id, exclude_org: org.name }) }

    context "when there are zero matches" do
      let(:css_id) { users.first.css_id + "foobar" }

      it "returns empty array" do
        subject

        expect(response.status).to eq(200)
        expect(body["users"]).to eq([])
      end
    end

    context "when the only match is already in the Org" do
      before do
        org.users << users.first
      end

      let(:css_id) { users.first.css_id }

      it "returns empty array" do
        subject

        expect(response.status).to eq(200)
        expect(body["users"]).to eq([])
      end
    end

    context "when the css_id is really a full_name" do
      let!(:users) { [create(:user, full_name: "Foo Bar"), create(:user, full_name: "Jill Smith")] }
      let(:css_id) { users.first.full_name }

      it "matches by name" do
        subject

        expect(response.status).to eq(200)

        found_users = body["users"]["data"]
        expect(found_users.count).to eq(1)
        expect(found_users.first["id"]).to eq(users.first.id.to_s)
      end
    end
  end

  describe "GET /user?css_id=<css_id>" do
    let(:user) { create(:user) }
    let(:params) { {} }

    subject { get(:search_by_css_id, params: params) }

    before { User.authenticate!(user: user) }

    context "when the user is not a BVA admin" do
      before { allow_any_instance_of(Bva).to receive(:user_has_access?).and_return(false) }

      it "redirects to /unauthorized" do
        subject

        expect(response.status).to eq(302)
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "when the user is a BVA admin" do
      before { allow_any_instance_of(Bva).to receive(:user_has_access?).and_return(true) }

      context "when no css_id parameter is provided" do
        it "returns an error" do
          subject

          expect(response.status).to eq(400)
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["detail"]).to eq("Must provide a css id")
        end
      end

      context "when an incorrect css_id parameter is provided" do
        let(:css_id) { "0" }
        let(:params) { { css_id: css_id } }

        it "returns an error" do
          subject

          expect(response.status).to eq(404)
        end
      end

      context "when a valid css_id parameter is provided" do
        let(:params) { { css_id: user.css_id } }

        it "returns a valid response with the expected user" do
          subject

          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)
          expect(response_body["user"]["id"]).to eq(user.id)
          expect(response_body["user"]["css_id"]).to eq(user.css_id)
        end
      end
    end
  end

  describe "PATCH /users/:user_id" do
    let(:params) { { id: user.id, status: new_status } }
    let(:user) { create(:user, status: old_status) }
    let(:new_status) { Constants.USER_STATUSES.inactive }
    let(:old_status) { Constants.USER_STATUSES.active }

    context "when current user is not a BVA admin" do
      it "returns unauthorized" do
        patch :update, params: params

        expect(response.status).to eq(302)
        expect(response).to redirect_to("/unauthorized")
      end
    end

    context "when current user is a BVA admin" do
      before { Bva.singleton.add_user(authenticated_user) }

      context "when marking the user inactive" do
        context "and the user is active" do
          it "marks the user as inactive" do
            patch :update, params: params

            expect(response.status).to eq(200)
            response_body = JSON.parse(response.body)
            expect(response_body.length).to eq(1)
            expect(response_body["user"]["status"]).to eq(new_status)
          end
        end

        context "and the user is already inactive" do
          let(:old_status) { Constants.USER_STATUSES.inactive }

          it "does not change the user status" do
            patch :update, params: params

            expect(response.status).to eq(200)
            response_body = JSON.parse(response.body)
            expect(response_body.length).to eq(1)
            expect(response_body["user"]["status"]).to eq(old_status)
          end
        end
      end
    end
  end
end
