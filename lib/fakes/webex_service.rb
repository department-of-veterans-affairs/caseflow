# frozen_string_literal: true

class Fakes::WebexService < ExternalApi::WebexService
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
          "message": "Id is not valid"
        }.with_indifferent_access
      )
    end

    def bad_access_response
      HTTPI::Response.new(
        403,
        {},
        {
          "error": "BadRequestError",
          "message": "Conference link cannot be created due to insufficient privileges"
        }.with_indifferent_access
      )
    end

    def distribution_not_found_response
      HTTPI::Response.new(
        404,
        {},
        {
          "error": "BadRequestError",
          "message": "Conference link does not exist at this time"
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

        }.with_indifferent_access
      )
    end

    # rubocop:disable Metrics/MethodLength
    # GET: /package-manager-service/distribution/{id}
    def webex_conference_response(_distribution_id)
      HTTPI::Response.new(
        200,
        {},
        {
          'fake_key': 'fake_value'
        }.with_indifferent_access
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
