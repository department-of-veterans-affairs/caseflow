# frozen_string_literal: true

describe OrganizationsController, :postgres, type: :controller do
  describe "GET /organizations/:organization" do
    let(:participant_id) { "123456" }
    let(:vso_participant_id) { Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID }
    let(:vso) { Vso.create!(participant_id: vso_participant_id, url: "american-legion", name: "Vso") }
    let(:user) { create(:user, roles: ["VSO"]) }
    let(:vso_participant_ids) { Fakes::BGSServicePOA.default_vsos_poas }

    before do
      stub_const("BGSService", ExternalApi::BGSService)
      User.authenticate!(user: user)

      allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
        .with(css_id: user.css_id, station_id: user.station_id).and_return(participant_id)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
        .with(participant_id).and_return(vso_participant_ids)
    end

    subject { get :show, params: { url: vso.url } }

    context "when the user is a member of the VSO in bgs but not in caseflow" do
      it "allows the user access and adds them to the organization" do
        expect(user.organizations.include?(vso)).to eq false

        subject

        expect(response.status).to eq 200
        expect(user.reload.organizations.include?(vso)).to eq true
      end
    end

    context "when the user is a member of the VSO in bgs and also in caseflow" do
      before do
        vso.add_user(user)
        expect_any_instance_of(Organization).not_to receive(:add_user)
      end

      it "allows the user access but does not add them to the organization" do
        number_of_users_orgs = user.organizations.count
        expect(user.organizations.include?(vso)).to eq true

        subject

        expect(response.status).to eq 200
        expect(user.reload.organizations.count).to eq number_of_users_orgs
      end
    end

    context "when the user is not a member of the VSO" do
      before do
        expect_any_instance_of(Organization).not_to receive(:add_user)
        allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
          .with(participant_id).and_return(vso_participant_ids.last)
      end

      it "disallows the user access and does not add them to the organization" do
        expect(user.organizations.include?(vso)).to eq false

        subject

        expect(response.status).to eq 302
        expect(user.reload.organizations.include?(vso)).to eq false
      end
    end
  end

  describe "GET /organizations?type=organizationType" do
    let(:org) { VhaProgramOffice.create!(url: "test-vha-po", name: "Test VHA Program Office") }
    before { User.authenticate!(user: create(:user)) }
    subject { get :org_index, params: { type: org.type } }

    context "when a request is made to get orgs of a certain type" do
      it "returns the appropriate information" do
        subject
        response_body = JSON.parse(response.body)
        org_attr = response_body["organizations"]["data"][0]["attributes"]

        expect(response.status).to eq 200
        expect(response_body["organizations"]["data"].size).to eq 1
        expect(org_attr["id"]).to eq org.id
        expect(org_attr["name"]).to eq org.name
      end
    end
  end
end
