class Dispatch
  class << self

    def validate_claim(claim)
      # TODO(jd): Add validations to verify establish claim data
    end

    def establish_claim!(claim:, task:)
      validate_claim(claim)

      Appeal.repository.establish_claim(claim)
      task.complete!(0)
    end

  end
end
