# frozen_string_literal: true

class Fakes::PacManService < ExternalApi::PacManService
  class << self
    def send_communication_package_request(file_number, name, document_references:)
      document_references.each do |document_reference|
        request = package_request(file_number, name, document_reference)
        fake_package_request(request)
      end
    end

    def send_distribution_request(package_id, recipient, destinations:)
      destinations.each do |destination|
        request = distribution_request(package_id, recipient, destination)
        fake_distribution_request(request)
      end
    end

    def get_distribution_request(distribution_id)
      request = {
        endpoint: GET_DISTRIBUTION_ENDPOINT + distribution_id, method: :get
      }
      fake_distribution_response(request)
    end

    private

    def bad_request_response
      HTTPI::Response.new(
        400,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "participant id is not valid"
        )
      )
    end

    def bad_access_response
      HTTPI::Response.new(
        403,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "package cannot be created because of insufficient privileges"
        )
      )
    end

    def distribution_not_found_response
      HTTPI::Response.new(
        404,
        {},
        OpenStruct.new(
          "error": "BadRequestError",
          "message": "distribution does not exist at this time"
        )
      )
    end

    def fake_package_request
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": "",
          "fileNumber": "073-claimant-appeal-file-number",
          "documentReferences": {
            "id": "123",
            "copies": 2
          },
          "status": "",
          "createdDate": "",
          "name": "name"
        )
      )
    end

    # rubocop:disable Metrics/MethodLength
    def fake_distribution_request
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": "12345",
          "recipient": {
            "type": "person",
            "name": "bob joe",
            "firstName": "bob",
            "middleName": "",
            "lastName": "joe",
            "participant_id": "123455667",
            "poaCode": "",
            "claimantStationOfJurisdiction": ""
          },
          "description": "bad",
          "communicationPackageId": "",
          "destinations": {
            "type": "email",
            "addressLine1": "",
            "addressLine2": "",
            "addressLine3": "",
            "addressLine4": "",
            "addressLine5": "",
            "addressLine6": "",
            "treatLine2AsAddressee": 0,
            "treatLine3AsAddressee": 0,
            "city": "",
            "state": "",
            "postalCode": "",
            "countryName": "",
            "emailAddress": "",
            "phoneNumber": ""
          },
          "status": "",
          "sentToCbcmDate": ""
        )
      )
    end
    # rubocop:enable Metrics/MethodLength

    def fake_distribution_response(distribution_id)
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": "123232323",
          "recipient": {
            "type": "person",
            "name": "bob joe",
            "firstName": "bob",
            "middleName": "",
            "lastName": "joe",
            "participant_id": "123455667",
            "poaCode": "",
            "claimantStationOfJurisdiction": ""
          },
          "description": "bad",
          "communicationPackageId": "",
          "destinations": {
            "type": "email",
            "addressLine1": "",
            "addressLine2": "",
            "addressLine3": "",
            "addressLine4": "",
            "addressLine5": "",
            "addressLine6": "",
            "treatLine2AsAddressee": 0,
            "treatLine3AsAddressee": 0,
            "city": "",
            "state": "",
            "postalCode": "",
            "countryName": "",
            "emailAddress": "",
            "phoneNumber": ""
          },
          "status": "",
          "sentToCbcmDate": ""
        )
      )
    end
  end
end
