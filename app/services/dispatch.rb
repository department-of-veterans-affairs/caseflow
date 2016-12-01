class Dispatch
  class InvalidClaimError < StandardError; end

  class << self

    def validate_claim(claim)
      # TODO(jd): Add validations to verify establish claim data
      true
    end

    def establish_claim!(claim:, task:)
      full_claim = default_claim_values.merge(claim)

      raise InvalidClaimError unless validate_claim(full_claim)
      Appeal.repository.establish_claim!(full_claim)
      task.complete!(0)
    end

    def default_claim_values
      {
        "claim_type": "Claim"
      }
    end


  end
end
