# frozen_string_literal: true

class CaseReview < Organization
  def self.singleton
    # after the production database is correct, replace the tmp function with CaseReview.first
    find_and_update_incorrect_bva_intake || CaseReview.create(name: "Case Review", url: "case-review")
  end

  private

  # temporary function to split the original mistake where the org Case Review was
  # referred to as BvaIntake. Can be removed after the production database is up to date.
  def self.find_and_update_incorrect_bva_intake
    # check if the mismatch exists; if not default back to BvaIntake.first
    case_review_misnamed = Organization.find_by(name: "Case Review", type: "BvaIntake")
    return CaseReview.first unless case_review_misnamed

    # we're the first invocation - fix the mismatch
    case_review_misnamed.update(type: "CaseReview")

    # return CaseReview.first; if it doesn't exist it will fall through up in singleton to the create - though it _should_ since we just created it via that update!
    CaseReview.first
  end
end
