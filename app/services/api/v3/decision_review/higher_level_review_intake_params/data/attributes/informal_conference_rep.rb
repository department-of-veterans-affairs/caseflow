class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes::InformalConferenceRep < Api::V3::DecisionReview::Params
  def initialize(params)
    @hash = params
    @errors = type_error_for_key(
      ["name", NULLABLE_STRING],
      ["phoneNumber", NULLABLE_STRING],
      ["phoneNumberCountryCode", NULLABLE_STRING],
      ["phoneNumberExt", NULLABLE_STRING]
    )
  end
end
