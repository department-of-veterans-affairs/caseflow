# frozen_string_literal: true

class ExternalApi::VADotGovService::ResponseMessage
  attr_reader :key

  def initialize(message)
    @key = message[:key]
  end

  def error
    if address_could_not_be_found?
      Caseflow::Error::VaDotGovAddressCouldNotBeFoundError.new(
        code: 500,
        message: "Address could not be found on a map."
      )
    elsif invalid_input?
      Caseflow::Error::VaDotGovInvalidInputError.new(
        code: 500,
        message: "Address information is incomplete."
      )
    elsif multiple_address?
      Caseflow::Error::VaDotGovMultipleAddressError.new(
        code: 500,
        message: "There are multiple locations that match address."
      )
    end
  end

  private

  def address_could_not_be_found?
    %w[AddressCouldNotBeFound SpectrumServiceAddressError].include?(key)
  end

  def invalid_input?
    %w[DualAddressError InsufficientInputData InvalidRequestCountry
       InvalidRequestNonStreetAddress InvalidRequestPostalCode InvalidRequestState
       InvalidRequestStreetAddress].include?(key)
  end

  def multiple_address?
    key == "MultipleAddressError"
  end
end
