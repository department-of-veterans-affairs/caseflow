# frozen_string_literal: true

class Fakes::PacmanService < ExternalApi::PacmanService
  COMMUNICATION_PACKAGE_UUID = "24eb6a66-3833-4de6-bea4-4b614e55d5ac"
  DISTRIBUTION_UUID = "201cef13-49ba-4f40-8741-97d06cee0270"

  class << self
    def send_communication_package_request(file_number, name, document_references)
      fake_package_request(file_number, name, document_references)
    end

    def send_distribution_request(package_id, recipient, destinations)
      [fake_distribution_request(package_id, recipient, destinations)]
    end

    def get_distribution_request(distribution_uuid)
      distribution = VbmsDistribution.find_by(uuid: distribution_uuid)

      return distribution_not_found_response unless distribution

      fake_distribution_response(distribution.uuid)
    end

    private

    def bad_request_response
      HTTPI::Response.new(
        400,
        {},
        {
          "error": "BadRequestError",
          "message": "participant id is not valid"
        }.with_indifferent_access
      )
    end

    def bad_access_response
      HTTPI::Response.new(
        403,
        {},
        {
          "error": "BadRequestError",
          "message": "package cannot be created because of insufficient privileges"
        }.with_indifferent_access
      )
    end

    def distribution_not_found_response
      HTTPI::Response.new(
        404,
        {},
        {
          "error": "BadRequestError",
          "message": "distribution does not exist at this time"
        }.with_indifferent_access
      )
    end

    # POST: /package-manager-service/communication-package
    def fake_package_request(file_number, name, document_references)
      HTTPI::Response.new(
        201,
        {},
        {
          "id" => COMMUNICATION_PACKAGE_UUID,
          "fileNumber": file_number,
          "name": name,
          "documentReferences": document_references,
          "status": "NEW",
          "createDate": ""
        }.with_indifferent_access
      )
    end

    # POST: /package-manager-service/distribution
    def fake_distribution_request(package_id, recipient, destinations)
      HTTPI::Response.new(
        201,
        {},
        {
          "id": DISTRIBUTION_UUID,
          "recipient": recipient,
          "description": "bad",
          "communicationPackageId": package_id,
          "destinations": destinations,
          "status": "",
          "sentToCbcmDate": ""
        }.with_indifferent_access
      )
    end

    # rubocop:disable Metrics/MethodLength
    # GET: /package-manager-service/distribution/{id}
    def fake_distribution_response(_distribution_id)
      HTTPI::Response.new(
        200,
        {},
        {
          "id": DISTRIBUTION_UUID,
          "recipient": {
            "type": "system",
            "id": "a050a21e-23f6-4743-a1ff-aa1e24412eff",
            "name": "VBMS-C"
          },
          "description": "Staging Mailing Distribution",
          "communicationPackageId": 1,
          "destinations": [{
            "type": "physicalAddress",
            "id": "28440040-51a5-4d2a-81a2-28730827be14",
            "status": "",
            "cbcmSendAttemptDate": "2022-06-06T16:35:27.996",
            "addressLine1": "POSTMASTER GENERAL",
            "addressLine2": "UNITED STATES POSTAL SERVICE",
            "addressLine3": "475 LENFANT PLZ SW RM 10022",
            "addressLine4": "SUITE 123",
            "addressLine5": "APO AE 09001-5275",
            "addressLine6": "",
            "treatLine2AsAddressee": true,
            "treatLine3AsAddressee": true,
            "city": "WASHINGTON DC",
            "state": "DC",
            "postalCode": "12345",
            "countryName": "UNITED STATES",
            "countryCode": "us"
          }],
          "status": "",
          "sentToCbcmDate": ""
        }.with_indifferent_access
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
