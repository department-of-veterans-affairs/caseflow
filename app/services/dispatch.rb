class Dispatch
  class InvalidClaimError < StandardError; end

  class << self
    def validate_claim(_claim)
      # TODO(jd): Add validations to verify establish claim data
      # true
      true
    end

    def establish_claim!(claim:, task:)
      binding.pry
      full_claim = default_claim_values.merge(claim)

      fail InvalidClaimError unless validate_claim(full_claim)
      end_product = Appeal.repository.establish_claim!(claim: full_claim,
                                                       appeal: task.appeal)

      task.complete!(status: 0, end_product: end_product)
    end

    def default_claim_values
      {
        # TODO(jd): Make this attr dynamic in future PR once
        # we support routing a claim based on special issues
        station_of_jurisdiction: "317",
        claim_type: "Claim",
        payee_code: "00"
      }
    end
  end
end
