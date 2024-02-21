# frozen_string_literal: true

module Events::DecisionReviewCreate::UpdatedVacolsOnOptin
  # Updates the Caseflow and VACOLS DB when Legacy Issues Optin to AMA
  # the decision review argument being passed in can either be a Higher Level Review or a Supplemental Claim
  # the decision review hash must have a benefit type.
  def self.update!(decision_review)
    LegacyOptinManager.new(decision_review: decision_review).process!

    # catch the error that is produced
  end
end
