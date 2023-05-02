# frozen_string_literal: true

class ExternalApi::PacManService
  BASE_URL = ENV["PACMAN_API_URL"]
  SEND_DISTRIBUTION_ENDPOINT = "package-manager-service/distribution"
  SEND_PACKAGE_ENDPOINT = "package-manager-service/communication-package"
  GET_DISTRIBUTION_ENDPOINT = "package-manager-service/distribution/"

  class << self
    def send_communication_package_request(file_number, name, document_references:)
      document_references.each do |document_reference|
        request = package_request(file_number, name, document_reference)
        send_pacman_request(request)
      end
    end

    def send_distribution_request(package_id, recipient, destinations:)
      destinations.each do |destination|
        request = distribution_request(package_id, recipient, destination)
        send_pacman_request(request)
      end
    end

    def get_distribution_request(distribution_id)
      request = {
        endpoint: GET_DISTRIBUTION_ENDPOINT + distribution_id, method: :get
      }
      send_pacman_request(request)
    end

    def package_request(file_number, name, document_reference)
      request = {
        body: {
          fileNumber: file_number,
          name: name,
          documentReferences: {
            id: document_reference[:id],
            copies: document_reference[:copies]
          }
        },
        headers: HEADERS,
        endpoint: SEND_PACKAGE_ENDPOINT, method: :post
      }
      request
    end

    def distribution_request(package_id, recipient, destination)
      request = {
        body: {
          communicationPackageId: package_id,
          recipient: {
            type: recipient.type,
            name: recipient.name,
            firstName: recipient.first_name,
            middleName: recipient.middle_name,
            lastName: recipient.last_name,
            participant_id: recipient.participant_id,
            poaCode: recipient.poa_code,
            claimantStationOfJurisdiction: recipient.claimant_station_of_jurisdiction
          },
          destinations: {
            type: destination[:type],
            addressLine1: destination[:addressLine1],
            addressLine2: destination[:addressLine2],
            addressLine3: destination[:addressLine3],
            addressLine4: destination[:addressLine4],
            addressLine5: destination[:addressLine5],
            addressLine6: destination[:addressLine6],
            treatLine2AsAddressee: destination[:treatLine2AsAddressee],
            treatLine3AsAddressee: destination[:treatLine3AsAddressee],
            city: destination[:city],
            state: destination[:state],
            postalCode: destination[:postalCode],
            countryName: destination[:countryName],
            emailAddress: destination[:emailAddress],
            phoneNumber: destination[:phoneNumber]
          }
        },
        headers: HEADERS,
        endpoint: SEND_PACKAGE_ENDPOINT, method: :post
      }
      request
    end

    def send_pacman_request(query: {}, headers: {}, endpoint:, method: :get, body: nil)
      url = URI.escape(BASE_URL + endpoint)
      request = HTTPI::Request.new(url)
      request.query = query
      request.open_timeout = 30
      request.read_timeout = 30
      request.body = body.to_json unless body.nil?
      # not sure how user validation will be handled
      request.headers = headers.merge(apikey: ENV["PACMAN_API_KEY"])
      sleep 1

      # FIXME idk what the url is
      MetricsService.record("pacman #{method.to_s.upcase} request to #{url}",
                            service: :va_dot_gov,
                            name: endpoint) do
        case method
        when :get
          HTTPI.get(request)
        when :post
          HTTPI.post(request)
        end
      end
    end
  end
end
