describe Vso do
  let(:participant_id) { "123456" }
  let(:vso_participant_id) { "789" }

  let(:vso) do
    Vso.create(
      participant_id: vso_participant_id
    )
  end

  let(:user) do
    create(:user, roles: ["VSO"])
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
    BGSService = ExternalApi::BGSService
    RequestStore[:current_user] = user

    allow_any_instance_of(BGS::SecurityWebService).to receive(:find_participant_id)
      .with(css_id: user.css_id, station_id: user.station_id).and_return(participant_id)
    allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_id)
      .with(participant_id).and_return(vso_participant_ids)
  end

  after do
    BGSService = Fakes::BGSService
  end

  context "#user_has_access?" do
    subject { vso.user_has_access?(user) }

    context "when the users participant_id is associated with this VSO" do
      it "returns true" do
        is_expected.to be_truthy
      end
    end

    context "when the users participant_id is associated with a different VSO" do
      let(:vso) do
        Vso.create(
          participant_id: "999"
        )
      end

      it "returns false" do
        is_expected.to be_falsey
      end
    end

    context "when the users participant_id is associated with no VSOs" do
      let(:vso_participant_ids) { [] }

      it "returns false" do
        is_expected.to be_falsey
      end
    end

    context "when the user does not have the VSO role" do
      let(:user) do
        create(:user, roles: ["Other Role"])
      end

      it "returns false" do
        is_expected.to be_falsey
      end
    end
  end
end
