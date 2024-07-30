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

    context "when there are organizations in the database" do
      let!(:vsos) { create_list(:vso, 5) }
      let!(:dvc_team_count) { 2.times { DvcTeam.create_for_dvc(create(:user)) } }
      let!(:judge_team_count) { 3.times { JudgeTeam.create_for_judge(create(:user)) } }
      let!(:private_bars) { create_list(:private_bar, 4) }
      let!(:other_orgs) { create_list(:organization, 7) }
      let!(:rpos) { create_list(:education_rpo, 3) }

      # Increase the count of other orgs to account for the Bva organization the current user is a member of.
      let!(:other_org_count) { other_orgs.count + 1 }
      context "when current user is a member of the Bva organization" do
        it "properly returns the list of organizations" do
          get(:index, format: :json)

          expect(response.status).to eq(200)

          response_body = JSON.parse(response.body)
          expect(response_body["vsos"].length).to eq(vsos.count)
          expect(response_body["dvc_teams"].length).to eq(dvc_team_count)
          expect(response_body["judge_teams"].length).to eq(judge_team_count)
          expect(response_body["judge_teams"].first["user_admin_path"].present?).to be true
          expect(response_body["judge_teams"].first["accepts_priority_pushed_cases"]).to be true
          expect(response_body["judge_teams"].first["current_user_can_toggle_priority_pushed_cases"]).to be false
          expect(response_body["private_bars"].length).to eq(private_bars.count)
          expect(response_body["private_bars"].first["accepts_priority_pushed_cases"]).to be nil
          expect(response_body["other_orgs"].length).to eq(other_org_count)
          expect(response_body["education_rpos"].length).to eq(rpos.count)
        end
      end

      context "when current user is a DVC" do
        before do
          dvc = create(:user)
          DvcTeam.create_for_dvc(dvc)
          User.authenticate!(user: dvc)
        end

        it "properly returns only judge teams with no link to team admin pages" do
          get(:index, format: :json)

          expect(response.status).to eq(200)

          response_body = JSON.parse(response.body)
          expect(response_body["judge_teams"].length).to eq(judge_team_count)
          expect(response_body["judge_teams"].first["user_admin_path"].present?).to be false
          expect(response_body["judge_teams"].first["accepts_priority_pushed_cases"]).to be true
          expect(response_body["judge_teams"].first["current_user_can_toggle_priority_pushed_cases"]).to be true
          expect(response_body["vsos"]).to eq nil
          expect(response_body["private_bars"]).to eq nil
          expect(response_body["other_orgs"]).to eq nil
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

      context "when toggling priority push" do
        let(:params) { { id: params_id, organization: { accepts_priority_pushed_cases: true } } }

        it "updates the existing organization record and returns the expected structure" do
          expect(org.accepts_priority_pushed_cases).to be nil
          patch(:update, params: params, format: :json)

          expect(org.reload.accepts_priority_pushed_cases).to be true

          expect(response.status).to eq(200)
          response_body = JSON.parse(response.body)
          expect(response_body["org"]["accepts_priority_pushed_cases"]).to be true
        end
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

  describe "POST /team_management/dvc_team/:id" do
    let(:dvc) { create(:user) }
    let(:dvc_id) { dvc.id }
    let(:params) { { user_id: dvc_id } }

    context "for a user who does not exist" do
      let(:dvc_id) { "fake ID" }
      it "returns a 404 error" do
        post(:create_dvc_team, params: params, format: :json)
        expect(response.status).to eq(404)
      end
    end

    context "for a user who already has a DvcTeam" do
      before { DvcTeam.create_for_dvc(dvc) }
      it "returns a 400 error" do
        post(:create_dvc_team, params: params, format: :json)
        expect(response.status).to eq(400)
      end
    end

    context "for a user who does not yet have a DvcTeam" do
      it "properly creates new organization" do
        post(:create_dvc_team, params: params, format: :json)
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        org = DvcTeam.find(response_body["org"]["id"])
        expect(org.dvc.id).to eq(dvc.id)
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

    context "when adding another org with the same participant_id" do
      before { post(:create_private_bar, params: params, format: :json) }
      it "returns error" do
        similar_params = params.dup.tap { |parameters| parameters[:organization][:url] = "dup-org" }
        post(:create_private_bar, params: similar_params, format: :json)
        expect(response.status).to eq(400)
        response_body = JSON.parse(response.body)
        error_message = "Participant ID #{participant_id} is already used for existing team 'New Private Bar org'"
        expect(response_body["errors"].first["detail"]).to start_with error_message
      end
    end
  end
end
