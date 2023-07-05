# frozen_string_literal: true

class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :api

  # Purpose: performs job
  #
  # takes in VbmsUploadedDocument object and JSON payload
  # mail_package looks like this:
  # {
  #   "distributions": [
  #     {
  #       "recipient_info": json of MailRequest object
  #     }
  #   ]
  #   "copies": integer value,
  #   "created_by_id": integer value
  # }
  #
  # Response: n/a
  def perform(document_to_mail, mail_package)
    begin
      package_response = PacmanService.send_communication_package_request(
        document_to_mail.veteran_file_number,
        get_package_name(document_to_mail),
        document_referenced(document_to_mail.document_version_reference_id, mail_package[:copies])
      )
      log_info(package_response)

      fail Caseflow::Error::PacmanApiError if package_response.error?
    rescue Caseflow::Error::PacmanApiError => error
      log_error(error)
    else
      vbms_comm_package = create_package(document_to_mail, mail_package)
      vbms_comm_package.update!(status: "success", uuid: parse_pacman_id(package_response))
      create_distribution_request(vbms_comm_package.id, mail_package)
    end
  end

  private

  def parse_pacman_id(pacman_response)
    JSON.parse(pacman_response.body)["id"]
  end

  # Purpose: arranges id and copies to pass into package post request
  #
  # takes in VbmsUploadedDocument id and copies integer
  #
  # Response: Array of json with document id and copies
  def document_referenced(doc_id, copies)
    [{ "id": doc_id, "copies": copies }]
  end

  # Purpose: Creates new VbmsCommunicationPackage
  #
  # takes in VbmsUploadedDocument object and MailRequest object
  #
  # Response: new VbmsCommunicationPackage object
  # :reek:FeatureEnvy
  def create_package(document_to_mail, mail_package)
    VbmsCommunicationPackage.new(
      comm_package_name: get_package_name(document_to_mail),
      created_at: Time.zone.now,
      created_by_id: mail_package[:created_by_id],
      copies: mail_package[:copies],
      file_number: document_to_mail.veteran_file_number,
      status: nil,
      updated_at: Time.zone.now,
      updated_by_id: mail_package[:created_by_id],
      document_mailable_via_pacman: document_to_mail
    )
  end

  def get_package_name(document_to_mail)
    "#{document_to_mail.document_name}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
  end

  # Purpose: sends distribution POST request to Pacman API
  #
  # takes in VbmsCommunicationPackage id (string) and MailRequest object
  #
  # Response: n/a
  def create_distribution_request(package_id, mail_package)
    distributions = mail_package[:distributions]
    distributions.each do |dist|
      begin
        distribution = VbmsDistribution.find(dist[:vbms_distribution_id])
        distribution_response = PacmanService.send_distribution_request(
          package_id,
          get_recipient_hash(distribution),
          get_destinations_hash(dist)
        )
        log_info(distribution_response)
        distribution.update!(vbms_communication_package_id: package_id, uuid: parse_pacman_id(distribution_response))
      rescue Caseflow::Error::PacmanApiError => error
        log_error(error)
      end
    end
  end

  # Purpose: creates recipient hash from VbmsDistribution attributes
  #
  # takes in VbmsDistribution object
  #
  # Response: hash that is needed in Pacman API distribution POST requests
  def get_recipient_hash(distribution)
    {
      type: distribution.recipient_type,
      name: distribution.name,
      firstName: distribution.first_name,
      middleName: distribution.middle_name,
      lastName: distribution.last_name,
      participantId: distribution.participant_id,
      poaCode: distribution.poa_code,
      claimantStationOfJurisdiction: distribution.claimant_station_of_jurisdiction
    }
  end

  # Purpose: creates destination hash from VbmsDistributionDestination attributes
  #
  # takes in VbmsDistributionDestination object
  #
  # Response: array that holds a hash
  def get_destinations_hash(destination)
    [{
      "type" => destination["destination_type"],
      "addressLine1" => destination["address_line_1"],
      "addressLine2" => destination["address_line_2"],
      "addressLine3" => destination["address_line_3"],
      "addressLine4" => destination["address_line_4"],
      "addressLine5" => destination["address_line_5"],
      "addressLine6" => destination["address_line_6"],
      "treatLine2AsAddressee" => destination["treat_line_2_as_addressee"],
      "treatLine3AsAddressee" => destination["treat_line_3_as_addressee"],
      "city" => destination["city"],
      "state" => destination["state"],
      "postalCode" => destination["postal_code"],
      "countryName" => destination["country_name"],
      "countryCode" => destination["country_code"]
    }]
  end

  # Purpose: logging error in Rails and in Raven
  #
  # takes in error message (string)
  #
  # Response: n/a
  def log_error(error)
    uuid = SecureRandom.uuid
    error_msg = ERROR_MESSAGES[error.code] || "#{error.code} Unknown error has occurred."

    Rails.logger.error(error_msg + "Error ID: " + uuid)
    Raven.capture_exception(error, extra: { error_uuid: uuid })
  end

  ERROR_MESSAGES = {
    400 => "400 PacmanBadRequestError The server cannot create the new communication package due to a client error.",
    403 => "403 PacmanForbiddenError The server cannot create the new communication package" \
           "due to insufficient privileges.",
    404 => "404 PacmanNotFoundError The communication package could not be found but may be available" \
      "again in the future. Subsequent requests by the client are permissible.",
    500 => "500 PacmanInternalServerError The request was unable to be completed."
  }.freeze

  # Purpose: logs information in Rails logger
  #
  # takes in info message (string)
  #
  # Response: n/a
  def log_info(info_message)
    uuid = SecureRandom.uuid

    Rails.logger.info("#{info_message.body} - ID: #{uuid}")
  end
end
