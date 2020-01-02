# frozen_string_literal: true

describe AppealsForPOA, :all_dbs do
  describe "#call" do
    let(:veteran) { create(:veteran, file_number: "44556677", participant_id: participant_id) }
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: vbms_id)) }
    let(:appeal_for_vso) do
      create(:appeal, veteran: veteran, claimants: [build(:claimant, participant_id: participant_id)])
    end
    let!(:appeals) do
      [
        appeal_for_vso,
        create(:appeal, veteran: veteran, claimants: [build(:claimant, participant_id: participant_id_without_vso)]),
        legacy_appeal
      ]
    end

    let(:vbms_id) { LegacyAppeal.convert_file_number_to_vacols(veteran.file_number) }
    let(:participant_id) { "1234" }
    let(:participant_id_without_vso) { "5678" }
    let(:vso_participant_id) { "2452383" }
    let(:participant_ids) { [participant_id, participant_id_without_vso] }

    let(:poas) do
      [
        {
          ptcpnt_id: participant_id,
          power_of_attorney: {
            legacy_poa_cd: "071",
            nm: "PARALYZED VETERANS OF AMERICA, INC.",
            org_type_nm: "POA National Organization",
            ptcpnt_id: vso_participant_id
          }
        },
        {
          ptcpnt_id: participant_id_without_vso,
          power_of_attorney: {}
        }
      ]
    end

    before do
      stub_const("BGSService", ExternalApi::BGSService)
      RequestStore[:current_user] = create(:user)
      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_ids)
        .with(array_including(participant_ids)).and_return(poas)
    end

    subject do
      described_class.new(
        veteran_file_number: veteran.file_number,
        poa_participant_ids: [vso_participant_id, "other vso participant id"]
      )
    end

    it "returns only the case with vso assigned to it" do
      returned_appeals = subject.call
      expect(returned_appeals.count).to eq 2
      expect(returned_appeals).to contain_exactly(appeal_for_vso, legacy_appeal)
    end
  end
end
