# frozen_string_literal: true

class ExternalApi::VADotGovService::Response::ResponseMessage
  def initialize(message)
    @message = message
  end

  def error
    if address_could_not_be_found?
      Caseflow::Error::VaDotGovAddressCouldNotBeFoundError.new code: 500, message: message
    elsif invalid_input?
      Caseflow::Error::VaDotGovInvalidInputError.new code: 500, message: message
    elsif multiple_address?
      Caseflow::Error::VaDotGovMultipleAddressError.new code: 500, message: message
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
