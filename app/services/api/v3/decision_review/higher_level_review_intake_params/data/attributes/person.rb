class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data::Attributes::Person < Api::V3::DecisionReview::Params
  ADDRESS_FIELDS = %w[
    addressLine1
    addressLine2
    city
    stateProvinceCode
    zipPostalCode
    countryCode
  ]

  REQUIRED_FIELDS_IF_ANY_ADDRESS_FIELD_IS_PRESENT = %w[
    addressLine1
    addressLine2
    city
    stateProvinceCode
    zipPostalCode
  ]

  def person_errors
    Array.wrap(
      type_error(
        ["addressLine1", NULLABLE_STRING],
        ["addressLine2", NULLABLE_STRING],
        ["city", NULLABLE_STRING],
        ["stateProvinceCode", NULLABLE_STRING],
        ["countryCode", NULLABLE_STRING],
        ["zipPostalCode", NULLABLE_STRING],
        ["phoneNumber", NULLABLE_STRING],
        ["phoneNumberCountryCode", NULLABLE_STRING],
        ["phoneNumberExt", NULLABLE_STRING],
        ["emailAddress", NULLABLE_STRING]
      ) || incomplete_address_error
    ).flatten
  end

  def incomplete_address_error
    return nil if no_address_specified? || address_has_all_required_fields?

    "Address for #{self.hash_path_str} is incomplete. Missing: #{missing_address_fields}"
  end

  def no_address_specified?
    hash.slice(ADDRESS_FIELDS).none?
  end

  def address_has_all_required_fields?
    hash.slice(REQUIRED_FIELDS_IF_ANY_ADDRESS_FIELD_IS_PRESENT).all?
  end

  def missing_address_fields
    REQUIRED_FIELDS_IF_ANY_ADDRESS_FIELD_IS_PRESENT.select { |key| hash[key].nil? }
  end
end
