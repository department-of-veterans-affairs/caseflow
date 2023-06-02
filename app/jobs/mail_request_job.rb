# frozen_string_literal: true

class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(vbms_uploaded_document, mail_request)
    package_response = ExternalApi::PacmanService.send_communication_package_request(vbms_uploaded_document.veteran_file_number,
                                                                                     mail_request.name,
                                                                                     vbms_comm_package.document_referenced)
    log_info(package_response)
    vbms_comm_package = create_package(vbms_uploaded_document, mail_request)
# FIXME what do we want when the response is an error?
# should a VbmsCommunicationPackage object still be created?
    if package_response.code == 201
      vbms_comm_package.update!(status: "success")
      create_distribution_request(vbms_comm_package.id, mail_request)
    else
      vbms_comm_package.update!(status: "error")
      log_error(error_msg(package_response.code))
    end
  end
# FIXME how to get created_by_id
  def create_package(vbms_uploaded_document, mail_request)
    VbmsCommunicationPackage.new(
      comm_package_name: mail_request.name,
      created_at: Time.zone.now,
      created_by_id: "",
      copies: nil,
      file_number: vbms_uploaded_document.veteran_file_number,
      status: nil,
      updated_at: Time.zone.now,
      updated_by_id: " ",
      vbms_uploaded_document_id: vbms_uploaded_document.id
    )
  end

  def create_distribution_request(package_id, mail_request)
    distributions = VbmsDistribution.find(participant_id: mail_request.participant_id)
    distributions.each do |dist|
      distribution_destination = VbmsDistributionDestination.find(vbms_distribution_id: dist.id)
      distribution_response = ExternalApi::PacmanService.send_distribution_request(package_id,
                                                                                   get_recipient_hash(distribution),
                                                                                   get_destinations_hash(distribution_destination))
      log_info(distribution_response)
      if distribution_response.code == 201
        dist.update!(vbms_communication_package_id: package_id)
      else
        log_error(error_msg(distribution.code))
      end
    end
  end

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

  def get_destinations_hash(destination)
    [{
      "type" => destination.destination_type,
      "addressLine1" => destination.address_line_1,
      "addressLine2" => destination.address_line_2,
      "addressLine3" => destination.address_line_3,
      "addressLine4" => destination.address_line_4,
      "addressLine5" => destination.address_line_5,
      "addressLine6" => destination.address_line_6,
      "city" => destination.city,
      "state" => destination.state,
      "postalCode" => destination.postal_code,
      "countryName" => destination.country_name,
      "countryCode" => destination.country_code
    }]

  end

  def log_error(error_msg)
    uuid = SecureRandom.uuid
    Rails.logger.error(error_msg + "Error ID: " + uuid)
    Raven.capture_exception(error_msg, extra: { error_uuid: uuid })
  end

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

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info(info_message + "ID: " + uuid)
  end
end
