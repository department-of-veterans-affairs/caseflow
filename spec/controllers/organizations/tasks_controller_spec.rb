# frozen_string_literal: true

RSpec.describe Organizations::TasksController, :all_dbs, type: :controller do
  include PowerOfAttorneyMapper
  include TaskHelpers

  let(:participant_id) { "123456" }
  let(:vso_participant_id) { "789" }
  let(:url) { "american-legion" }
  let(:name) { "American Legion" }

  let(:vso) do
    Vso.create(
      participant_id: vso_participant_id,
      url: url,
      role: "VSO",
      name: name
    )
  end

  let!(:user) do
    User.authenticate!(roles: ["VSO"])
  end

  let(:vso_participant_ids) do
    [
      {
        legacy_poa_cd: "070",
        nm: "VIETNAM VETERANS OF AMERICA",
        org_type_nm: "POA National Organization",
        ptcpnt_id: vso_participant_id
      },
      {
        legacy_poa_cd: "071",
        nm: "PARALYZED VETERANS OF AMERICA, INC.",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "2452383"
      }
    ]
  end

  before do
    allow_any_instance_of(BGSService).to receive(:get_participant_id_for_user)
      .with(user).and_return(participant_id)
    allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_id)
      .with(participant_id).and_return(vso_participant_ids.map { |poa| get_poa_from_bgs_poa(poa) })
  end

  describe "GET organization/:organization_id/tasks" do
    let!(:tasks) do
      appeal = create_legacy_appeal_with_hearings
      [
        create(
          :task,
          appeal: appeal,
          appeal_type: "LegacyAppeal",
          type: :Task,
          assigned_to: vso
        ),
        create(
          :task,
          appeal: create(:appeal),
          type: :Task,
          assigned_to: vso
        )
      ]
    end

    context "when user has VSO role and belongs to the VSO" do
      it "should return tasks" do
        get :index, params: { organization_url: url }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["queue_config"]["tabs"].second["tasks"]

        expect(response_body.size).to eq 2
      end

      it "has a response body with the correct shape" do
        get(:index, params: { organization_url: url })
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)

        expect(response_body.keys).to match_array(%w[organization_name id is_vso queue_config])
      end
    end

    context "when user doesn't have proper role" do
      let!(:user) do
        User.authenticate!(roles: ["NO ROLE"])
      end

      it "should be redirected" do
        get :index, params: { organization_url: url }
        expect(response.status).to eq 302
      end
    end

    context "when user is not part of a VSO" do
      let(:vso_participant_ids) { [] }

      it "should be redirected" do
        get :index, params: { organization_url: url }
        expect(response.status).to eq 302
      end
    end
  end
end
