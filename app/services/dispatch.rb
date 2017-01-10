class Dispatch
  class InvalidClaimError < StandardError; end

  EP_STATUS = {
    "PEND" => "Pending",
    "CLR" => "Cleared",
    "CAN" => "Canceled"
  }.freeze
    
  EP_CODES = {
    "170APPACT" => "Appeal Action",
    "170APPACTPMC" => "PMC-Appeal Action",
    "170PGAMC" => "AMC-Partial Grant ",
    "170RMD" => "Remand",
    "170RMDAMC" => "AMC-Remand",
    "170RMDPMC" => "PMC-Remand",
    "172GRANT" => "Grant of Benefits",
    "172BVAG" => "BVA Grant",
    "172BVAGPMC" => "PMC-BVA Grant",
    "400CORRC" => "Correspondence",
    "400CORRCPMC" => "PMC-Correspondence",
    "930RC" => "Rating Control",
    "930RCPMC" => "PMC-Rating Control"
  }.freeze

  class << self
    def validate_claim(_claim)
      # TODO(jd): Add validations to verify establish claim data
      true
    end

    def establish_claim!(claim:, task:)
      full_claim = default_claim_values.merge(claim)

      fail InvalidClaimError unless validate_claim(full_claim)
      Appeal.repository.establish_claim!(claim: full_claim, appeal: task.appeal)
      task.complete!(0)
    end

    def default_claim_values
      {
        "claim_type" => "Claim"
      }
    end
  end
end
