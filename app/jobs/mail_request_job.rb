# frozen_string_literal: true

# This job syncs an EndProductEstablishment (end product manager) with up to date BGS and VBMS data
class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(vbms_comm_package)
    package_response = ExternalApi::PacmanService.send_communication_package_request(vbms_comm_package.file_number,
                                                                                     vbms_comm_package.comm_package_name,
                                                                                     vbms_comm_package.document_referenced)
    log_info(package_response)
    if package_response.code == 201
      vbms_comm_package.update!(status: "success")
      create_distribution(vbms_comm_package.id)
    else
      vbms_comm_package.update!(status: "error")
      log_error(error_msg(package_response.code))
    end
  end

  def create_distribution(package_id)
    dist = VbmsDistribution.find_by(vbms_communication_package_id: package_id)
    dist_dest = VbmsDistributionDestination.find_by(dist.id)
    distribution = ExternalApi::PacmanService.send_distribution_request(package_id, dist[:recipient], Array(dist_dest))
    log_info(distribution)
    if distribution.code != 201
      log_error(error_msg(distribution.code))
    end
    distribution
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
