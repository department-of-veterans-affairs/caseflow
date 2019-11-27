class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes::Claimant < Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes::Person
  def initialize(params)
    @hash = params
    @errors = person_errors + Array.wrap(type_error(
                                           ["participantId", String],
                                           ["payeeCode", String]
                                         ))
  end
end
