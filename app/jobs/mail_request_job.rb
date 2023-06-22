# frozen_string_literal: true

class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  # Purpose: performs job
  #
  # takes in VbmsUploadedDocument object and MailRequest object
  #
  # Response: n/a
  def perform(vbms_uploaded_document, mail_request)
    package_response = ExternalApi::PacmanService.send_communication_package_request(vbms_uploaded_document.veteran_file_number,
                                                                                     get_package_name(vbms_uploaded_document),
                                                                                     document_referenced(vbms_uploaded_document.id, mail_request[:copies]))
    log_info(package_response)
    vbms_comm_package = create_package(vbms_uploaded_document, mail_request)
    if package_response.code == 201
      vbms_comm_package.update!(status: "success")
      create_distribution_request(vbms_comm_package.id, mail_request)
    else
      vbms_comm_package.update!(status: "error")
      # log_error(error_msg(package_response.code))
    end
  end

  private

  def document_referenced(doc_id, copies)
    [{ "id": doc_id, "copies": copies }]
  end

  # Purpose: Creates new VbmsCommunicationPackage
  #
  # takes in VbmsUploadedDocument object and MailRequest object
  #
  # Response: new VbmsCommunicationPackage object
  def create_package(vbms_uploaded_document, mail_request)
    VbmsCommunicationPackage.new(
      comm_package_name: get_package_name(vbms_uploaded_document),
      created_at: Time.zone.now,
      created_by_id: mail_request[:created_by_id],
      copies: mail_request[:copies],
      file_number: vbms_uploaded_document.veteran_file_number,
      status: nil,
      updated_at: Time.zone.now,
      updated_by_id: mail_request[:created_by_id],
      vbms_uploaded_document_id: vbms_uploaded_document.id
    )
  end

  def get_package_name(vbms_uploaded_document)
    "#{vbms_uploaded_document.document_name}_#{Time.now.utc.strftime('%Y%m%d%k%M%S')}"
  end

  # Purpose: sends distribution POST request to Pacman API
  #
  # takes in VbmsCommunicationPackage id (string) and MailRequest object
  #
  # Response: n/a
  def create_distribution_request(package_id, mail_request)
    distributions = mail_request[:distributions]
    distributions.each do |dist|
      dist_hash = JSON.parse(dist)
      distribution = VbmsDistribution.find(dist_hash["vbms_distribution_id"])
      distribution_response = ExternalApi::PacmanService.send_distribution_request(package_id,
                                                                             get_recipient_hash(distribution),
                                                                             get_destinations_hash(dist_hash))
      log_info(distribution_response)
      if distribution_response.code == 201
        distribution.update!(vbms_communication_package_id: package_id)
      else
        # log_error(error_msg(distribution.code))
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
      participant_id: distribution.participant_id,
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
  def log_error(error_msg)
    uuid = SecureRandom.uuid
    Rails.logger.error(error_msg + "Error ID: " + uuid)
    Raven.capture_exception(error_msg, extra: { error_uuid: uuid })
  end

  # Purpose: gets an error message based on the error code
  #
  # takes in error code (int)
  #
  # Response: error message string
  def error_msg(code)
    if code == 400
      "400 PacmanBadRequestError The server cannot create the new communication package due to a client error "
    elsif code == 403
      "403 PacmanForbiddenError The server cannot create the new communication package due to insufficient privileges."
    elsif code == 404
      "404 PacmanNotFoundError The communication package could not be found but may be available again in the future.
       Subsequent requests by the client are permissible. "
    end
  end

  # Purpose: logs information in Rails logger
  #
  # takes in info message (string)
  #
  # Response: n/a
  def log_info(info_message)
    uuid = SecureRandom.uuid
    info_message.body.uuid = uuid
    Rails.logger.info(info_message)
  end
end
