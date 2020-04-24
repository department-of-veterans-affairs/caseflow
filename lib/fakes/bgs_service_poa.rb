# frozen_string_literal: true

class Fakes::BGSServicePOA
  include PowerOfAttorneyMapper

  PARALYZED_VETERANS_VSO_PARTICIPANT_ID = "2452383"
  VIETNAM_VETERANS_VOS_PARTICIPANT_ID = "789"
  PARALYZED_VETERANS_LEGACY_POA_CD = "071"
  PARALYZED_VETERANS_VSO_NAME = "PARALYZED VETERANS OF AMERICA, INC."
  POA_NATIONAL_ORGANIZATION = "POA National Organization"

  class << self
    # rubocop:disable Metrics/MethodLength
    def default_vsos
      [
        {
          file_number: "070-claimant-appeal-file-number",
          ptcpnt_id: "070-claimant-participant-id",
          power_of_attorney: {
            legacy_poa_cd: "070",
            nm: "VIETNAM VETERANS OF AMERICA",
            org_type_nm: POA_NATIONAL_ORGANIZATION,
            ptcpnt_id: VIETNAM_VETERANS_VOS_PARTICIPANT_ID
          }
        },
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
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def default_vsos_mapped
      default_vsos.map { |poa| get_poa_from_bgs_poa(poa) }
    end
  end
end
