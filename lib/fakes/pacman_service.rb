# frozen_string_literal: true

class Fakes::PacmanService < ExternalApi::PacmanService
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
          "name": "name",
          "documentReferences": {
            "id": "123",
            "copies": 2
          },
          "status": "",
          "createdDate": "",
          "name": ""
        )
      )
    end

    # rubocop:disable Metrics/MethodLength
    def fake_distribution_request
      HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": package_id,
          "recipient": {
            "type": recipient.type,
            "name": recipient.name,
            "firstName": recipient.first_name,
            "middleName": recipient.middle_name,
            "lastName": recipient.last_name,
            "participant_id": recipient.participant_id,
            "poaCode": recipient.poa_code,
            "claimantStationOfJurisdiction": recipient.claimant_station_of_jurisdiction
          },
          "description": "bad",
          "communicationPackageId": "",
          "destinations": {
            "type": destination[:type],
            "addressLine1": destination[:addressLine1],
            "addressLine2": destination[:addressLine2],
            "addressLine3": destination[:addressLine3],
            "addressLine4": destination[:addressLine4],
            "addressLine5": destination[:addressLine5],
            "addressLine6": destination[:addressLine6],
            "treatLine2AsAddressee": destination[:treatLine2AsAddressee],
            "treatLine3AsAddressee": destination[:treatLine3AsAddressee],
            "city": destination[:city],
            "state": destination[:state],
            "postalCode": destination[:postalCode],
            "countryName": destination[:countryName],
            "emailAddress": destination[:emailAddress],
            "phoneNumber": destination[:phoneNumber]
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
          "id": package_id,
          "recipient": {
            "type": recipient.type,
            "name": recipient.name,
            "firstName": recipient.first_name,
            "middleName": recipient.middle_name,
            "lastName": recipient.last_name,
            "participant_id": recipient.participant_id,
            "poaCode": recipient.poa_code,
            "claimantStationOfJurisdiction": recipient.claimant_station_of_jurisdiction
          },
          "description": "bad",
          "communicationPackageId": "",
          "destinations": {
            "type": destination[:type],
            "addressLine1": destination[:addressLine1],
            "addressLine2": destination[:addressLine2],
            "addressLine3": destination[:addressLine3],
            "addressLine4": destination[:addressLine4],
            "addressLine5": destination[:addressLine5],
            "addressLine6": destination[:addressLine6],
            "treatLine2AsAddressee": destination[:treatLine2AsAddressee],
            "treatLine3AsAddressee": destination[:treatLine3AsAddressee],
            "city": destination[:city],
            "state": destination[:state],
            "postalCode": destination[:postalCode],
            "countryName": destination[:countryName],
            "emailAddress": destination[:emailAddress],
            "phoneNumber": destination[:phoneNumber]
          },
          "status": "",
          "sentToCbcmDate": ""
        )
      )
    end
  end
end
