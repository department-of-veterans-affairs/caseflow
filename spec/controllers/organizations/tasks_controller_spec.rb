RSpec.describe Organizations::TasksController, type: :controller do
  include PowerOfAttorneyMapper

  let(:participant_id) { "123456" }
  let(:vso_participant_id) { "789" }
  let(:url) { "American-Legion" }

  let(:vso) do
    Vso.create(
      participant_id: vso_participant_id,
      url: url,
      role: "VSO"
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
      [
        create(
          :task,
          appeal: create(:appeal, veteran: create(:veteran)),
          appeal_type: "Appeal",
          type: :GenericTask,
          assigned_to: vso
        ),
        create(
          :task,
          appeal: create(:appeal, veteran: create(:veteran)),
          appeal_type: "Appeal",
          type: :GenericTask,
          assigned_to: vso
        )
      ]
    end

    context "when user has VSO role and belongs to the VSO" do
      it "should return tasks" do
        get :index, params: { organization_url: url }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq 2
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
