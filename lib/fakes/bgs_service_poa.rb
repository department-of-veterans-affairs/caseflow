# frozen_string_literal: true

class Fakes::BGSServicePOA
  include PowerOfAttorneyMapper

  PARALYZED_VETERANS_VSO_PARTICIPANT_ID = "2452383"
  VIETNAM_VETERANS_VSO_PARTICIPANT_ID = "2452415"
  PARALYZED_VETERANS_LEGACY_POA_CD = "071"
  VIETNAM_VETERANS_LEGACY_POA_CD = "070"
  PARALYZED_VETERANS_VSO_NAME = "PARALYZED VETERANS OF AMERICA, INC."
  VIETNAM_VETERANS_VSO_NAME = "VIETNAM VETERANS OF AMERICA"
  POA_NATIONAL_ORGANIZATION = "POA National Organization"
  AMERICAN_LEGION_VSO_NAME = "AMERICAN LEGION"

  class << self
    def vietnam_veterans_vso
      {
        file_number: "070-claimant-appeal-file-number",
        ptcpnt_id: "070-claimant-participant-id",
        power_of_attorney: {
          legacy_poa_cd: VIETNAM_VETERANS_LEGACY_POA_CD,
          nm: VIETNAM_VETERANS_VSO_NAME,
          org_type_nm: POA_NATIONAL_ORGANIZATION,
          ptcpnt_id: VIETNAM_VETERANS_VSO_PARTICIPANT_ID
        }
      }
    end

    def paralyzed_veterans_vso
      {
        file_number: "071-claimant-appeal-file-number",
        ptcpnt_id: "071-claimant-participant-id",
        power_of_attorney: {
          legacy_poa_cd: PARALYZED_VETERANS_LEGACY_POA_CD,
          nm: PARALYZED_VETERANS_VSO_NAME,
          org_type_nm: POA_NATIONAL_ORGANIZATION,
          ptcpnt_id: PARALYZED_VETERANS_VSO_PARTICIPANT_ID
        }
      }
    end

    def american_legion_vso
      {
        file_number: "072-claimant-appeal-file-number",
        ptcpnt_id: "072-claimant-participant-id",
        power_of_attorney: {
          legacy_poa_cd: "072",
          nm: AMERICAN_LEGION_VSO_NAME,
          org_type_nm: POA_NATIONAL_ORGANIZATION,
          ptcpnt_id: "54321"
        }
      }
    end

    def fake_poa
      {
        file_number: "073-claimant-appeal-file-number",
        ptcpnt_id: "073-claimant-participant-id",
        power_of_attorney: {
          legacy_poa_cd: "073",
          nm: Faker::Name.name,
          org_type_nm: ["POA Attorney", "POA Agent"].sample,
          ptcpnt_id: "073"
        }
      }
    end

    def random_poa_org
      [
        vietnam_veterans_vso,
        paralyzed_veterans_vso,
        american_legion_vso,
        fake_poa
      ].sample
    end

    def vietnam_veterans_vso_mapped
      get_claimant_poa_from_bgs_poa(vietnam_veterans_vso)
    end

    def paralyzed_veterans_vso_mapped
      get_claimant_poa_from_bgs_poa(paralyzed_veterans_vso)
    end

    def american_legion_vso_mapped
      get_claimant_poa_from_bgs_poa(american_legion_vso)
    end

    def default_vsos
      [vietnam_veterans_vso, paralyzed_veterans_vso]
    end

    def default_vsos_mapped
      default_vsos.map { |poa| get_claimant_poa_from_bgs_poa(poa) }
    end

    def default_vsos_poas
      default_vsos.map { |vso| vso[:power_of_attorney] }
    end
  end
end
