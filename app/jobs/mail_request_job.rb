# frozen_string_literal: true

# This job syncs an EndProductEstablishment (end product manager) with up to date BGS and VBMS data
class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(vbms_comm_package)
    package_response = ExternalApi::PacmanService.send_communication_package_request(vbms_comm_package.file_number,
                                                                            vbms_comm_package.comm_package_name,
                                                                            vbms_comm_package.document_referenced)
    if package_response.code == 201
      vbms_comm_package.update!(status: "success")
      distribution_response = create_distribution(vbms_comm_package.id)
    else
      vbms_comm_package.update!(status: "error")
    end
  end

  def create_distribution(package_id)
    dist = VbmsDistribution.find_by(vbms_communication_package_id: package_id)
    dist_dest = VbmsDistributionDestination.find_by(dist.id)
    distribution = ExternalApi::PacmanService.send_distribution_request(package_id, dist[:recipient], Array(dist_dest))
    distribution
  end

  def log_error(error)
    uuid = SecureRandom.uuid
    Rails.logger.error(error.to_s + "Error ID: " + uuid)
    Raven.capture_exception(error, extra: { error_uuid: uuid })
  end
end
