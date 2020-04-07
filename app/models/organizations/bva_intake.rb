# frozen_string_literal: true

class BvaIntake < Organization
  class << self
    def singleton
      # after the production database is correct, replace the tmp function with BvaIntake.first
      find_and_update_incorrect_bva_intake || BvaIntake.create(name: "Bva Intake", url: "bva-intake")
    end

    private

    # temporary function to split the original mistake where the org Case Review was
    # referred to as BvaIntake. Can be removed after the production database is up to date.
    def find_and_update_incorrect_bva_intake
      # check if the mismatch exists; if not default back to BvaIntake.first
      case_review_misnamed = Organization.find_by(name: "Case Review", type: "BvaIntake")
      return BvaIntake.first unless case_review_misnamed

      # we're the first invocation - fix the mismatch
      case_review_misnamed.update(type: "CaseReview")

      # return BvaIntake.first; if it doesn't exist it will fall through up in singleton to the create
      BvaIntake.first
    end
  end
end
