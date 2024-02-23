# frozen_string_literal: true

module Events::DecisionReviewCreate::UpdateVacolsOnOptin
  # Updates the Caseflow and VACOLS DB when Legacy Issues Optin to AMA
  # the decision review argument being passed in can either be a Higher Level Review or a Supplemental Claim
  # the decision review hash must have a benefit type.
  def self.process!(decision_review)
    if decision_review.legacy_opt_in_approved
      LegacyOptinManager.new(decision_review: decision_review).process!
    end
  # Catch the error and raise
  rescue Caseflow::Error::DecisionReviewCreateVacolsOnOptinError => error
    raise error
  end
end
