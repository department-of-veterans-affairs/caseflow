# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes < Api::V3::DecisionReview::Params
  def initialize(params)
    @hash = params
    @errors = Array.wrap(
      type_error_for_key(
        ["receiptDate", String],
        ["informalConference", BOOL],
        ["informalConferenceTimes", [Array, nil]],
        ["informalConferenceRep", OBJECT + [nil]],
        ["sameOffice", BOOL],
        ["legacyOptInApproved", BOOL],
        ["benefitType", String],
        ["veteran", OBJECT],
        ["claimant", OBJECT],
      ) || (
        self.class::Veteran.new(hash["veteran"]).errors +
        self.class::Claimant.new(hash["claimant"]).errors +
        (
          hash["informalConferenceRep"] ?
            self.class::InformalConferenceRep.new(hash["informalConferenceRep"]).errors :
            []
        )
      )
    ).flatten
  end
end
