# frozen_string_literal: true

class ExternalApi::VADotGovService::ResponseMessage
  attr_reader :message

  def initialize(message)
    @message = message
  end

  def error
    if address_could_not_be_found?
      Caseflow::Error::VaDotGovAddressCouldNotBeFoundError
    elsif invalid_input?
      Caseflow::Error::VaDotGovInvalidInputError
    elsif multiple_address?
      Caseflow::Error::VaDotGovMultipleAddressError
    end
  end

  private

  def address_could_not_be_found?
    %w[AddressCouldNotBeFound SpectrumServiceAddressError].include?(message)
  end

  def invalid_input?
    %w[DualAddressError InsufficientInputData InvalidRequestCountry
       InvalidRequestNonStreetAddress InvalidRequestPostalCode InvalidRequestState
       InvalidRequestStreetAddress].include?(message)
  end

  def multiple_address?
    message == "MultipleAddressError"
  end
end
