class Dispatch
  class InvalidClaimError < StandardError; end

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
