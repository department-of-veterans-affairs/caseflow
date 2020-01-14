# frozen_string_literal: true

describe TeamManagementController, :postgres, type: :controller do
  let(:user) { create(:user) }

  before do
    Bva.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  describe "GET /team_management" do
    context "when current user is not a member of the Bva organization" do
      before { User.authenticate!(user: create(:user)) }

      it "redirects to unauthorized" do
        get(:index, format: :json)

        expect(response.status).to eq(302)
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "when current user is a member of the Bva organization" do
      context "when there are organizations in the database" do
        let!(:vsos) { create_list(:vso, 5) }
        let!(:judge_team_count) { 3.times { JudgeTeam.create_for_judge(create(:user)) } }
        let!(:private_bars) { create_list(:private_bar, 4) }
        let!(:other_orgs) { create_list(:organization, 7) }

        # Increase the count of other orgs to account for the Bva organization the current user is a member of.
        let!(:other_org_count) { other_orgs.count + 1 }

        it "properly returns the list of organizations" do
          get(:index, format: :json)

          expect(response.status).to eq(200)

          response_body = JSON.parse(response.body)
          expect(response_body["vsos"].length).to eq(vsos.count)
          expect(response_body["judge_teams"].length).to eq(judge_team_count)
          expect(response_body["private_bars"].length).to eq(private_bars.count)
          expect(response_body["other_orgs"].length).to eq(other_org_count)
        end
      end
    end
  end

  describe "PATCH /team_management/:id" do
    let(:org) { create(:organization) }
    let(:org_name) { "Organization Name" }
    let(:url) { "url-after" }
    let(:participant_id) { "123456" }
    let(:params) { { id: params_id, organization: { name: org_name, url: url, participant_id: participant_id } } }

    context "for an organization ID that does not exist" do
      let(:params_id) { "fake ID" }

      it "returns a 404 error" do
        patch(:update, params: params, format: :json)
        expect(response.status).to eq(404)
      end
    end

    context "for an organization ID that exists" do
      let(:params_id) { org.id }

      it "updates the existing organization record and returns the expected structure" do
        patch(:update, params: params, format: :json)

        expect(org.reload.name).to eq(org_name)

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["org"]["participant_id"]).to eq(participant_id.to_s)
      end
    end
  end

  describe "POST /team_management/judge_team/:id" do
    let(:judge) { create(:user) }
    let(:judge_id) { judge.id }
    let(:params) { { user_id: judge_id } }

    context "for a user who does not exist" do
      let(:judge_id) { "fake ID" }
      it "returns a 404 error" do
        post(:create_judge_team, params: params, format: :json)
        expect(response.status).to eq(404)
      end
    end

    context "for a user who already has a JudgeTeam" do
      before { JudgeTeam.create_for_judge(judge) }
      it "returns a 400 error" do
        post(:create_judge_team, params: params, format: :json)
        expect(response.status).to eq(400)
      end
    end

    context "for a user who does not yet have a JudgeTeam" do
      it "properly creates new organization" do
        post(:create_judge_team, params: params, format: :json)
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        org = JudgeTeam.find(response_body["org"]["id"])
        expect(org.judge.id).to eq(judge.id)
      end
    end
  end

  describe "POST /team_management/national_vso" do
    let(:org_name) { "New VSO" }
    let(:url) { "vso-url" }
    let(:participant_id) { "123456" }
    let(:params) { { organization: { name: org_name, url: url, participant_id: participant_id } } }

    it "properly returns newly created organization" do
      post(:create_national_vso, params: params, format: :json)

      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      expect(response_body["org"]["name"]).to eq(org_name)
      expect(response_body["org"]["url"]).to eq(url)
      expect(response_body["org"]["participant_id"]).to eq(participant_id)

      org = Vso.find(response_body["org"]["id"])
      expect(org.name).to eq(org_name)
    end
  end

  describe "POST /team_management/field_vso" do
    let(:org_name) { "New Field VSO" }
    let(:url) { "field-vso-url" }
    let(:participant_id) { "123456" }
    let(:params) { { organization: { name: org_name, url: url, participant_id: participant_id } } }

    it "properly returns newly created organization" do
      post(:create_field_vso, params: params, format: :json)

      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      expect(response_body["org"]["name"]).to eq(org_name)
      expect(response_body["org"]["url"]).to eq(url)
      expect(response_body["org"]["participant_id"]).to eq(participant_id)

      org = FieldVso.find(response_body["org"]["id"])
      expect(org.name).to eq(org_name)
      expect(org.vso_config).to_not be_nil
    end
  end

  describe "POST /team_management/private_bar" do
    let(:org_name) { "New Private Bar org" }
    let(:url) { "private-bar-esq" }
    let(:participant_id) { "882771" }
    let(:params) { { organization: { name: org_name, url: url, participant_id: participant_id } } }

    it "properly returns newly created organization" do
      post(:create_private_bar, params: params, format: :json)

      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      expect(response_body["org"]["name"]).to eq(org_name)
      expect(response_body["org"]["url"]).to eq(url)
      expect(response_body["org"]["participant_id"]).to eq(participant_id)

      org = PrivateBar.find(response_body["org"]["id"])
      expect(org.name).to eq(org_name)
    end
  end
end
