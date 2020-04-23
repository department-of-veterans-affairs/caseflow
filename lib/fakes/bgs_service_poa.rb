# frozen_string_literal: true

class Fakes::BGSServicePOA
  PARALYZED_VETERANS_VSO_PARTICIPANT_ID = "2452383"
  VIETNAM_VETERANS_VOS_PARTICIPANT_ID = "789"

  class << self
    def default_vsos
      [
        {
          power_of_attorney: {
            legacy_poa_cd: "070",
            nm: "VIETNAM VETERANS OF AMERICA",
            org_type_nm: "POA National Organization",
            ptcpnt_id: VIETNAM_VETERANS_VOS_PARTICIPANT_ID
          }
        },
        {
          power_of_attorney: {
            legacy_poa_cd: "071",
            nm: "PARALYZED VETERANS OF AMERICA, INC.",
            org_type_nm: "POA National Organization",
            ptcpnt_id: PARALYZED_VETERANS_VSO_PARTICIPANT_ID
          }
        }
      ]
    end
  end
end
