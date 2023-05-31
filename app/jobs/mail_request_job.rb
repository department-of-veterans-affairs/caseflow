# frozen_string_literal: true

class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake
# copies based on number of recipients
# But then how to get document reference id?
# is that even needed still? if not, pacman service needs to be changed
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

  def create_distribution(package_id, mail_request)
    VbmsDistribution.new(
      claimant_station_of_jurisdiction: mail_request.claimant_station_of_jurisdiction,
      created_at: Time.zone.now,
      created_by_id: "",
      first_name: mail_request.first_name,
      last_name: mail_request.last_name,
      middle_name: mail_request.middle_name,
      name: mail_request.name,
      participant_id: mail_request.participant_id,
      poa_code: mail_request.poa_code,
      recipient_type: mail_request.recipient_type,
      updated_at: Time.zone.now,
      updated_by_id: "",
      vbms_communication_package_id: package_id
    )

  end

  def create_distribution_destinations(dist_id, mail_request)

  end

  def get_recipient_array(mail_request)

  end

  def get_destination_array(mail_request)

  end
# multiple recipients and destinations?
# how will those be packaged in mail_request?
  def create_distribution_request(package_id, mail_request)
    distribution_response = ExternalApi::PacmanService.send_distribution_request(package_id, dist[:recipient], Array(dist_dest))
    log_info(distribution_response)
    if distribution_response.code == 201
      distribution = create_distribution(package_id, mail_request)
      create_distribution_destinations
    else
      log_error(error_msg(distribution.code))
    end
    distribution.uuid
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
