class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes::Veteran < Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes::Person
  def initialize(params)
    @hash = params
    @errors = person_errors + Array.wrap(type_error_for_key(["fileNumberOrSsn", String]))
  end
end
