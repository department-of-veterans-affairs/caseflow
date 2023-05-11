# frozen_string_literal: true

# This job syncs an EndProductEstablishment (end product manager) with up to date BGS and VBMS data
class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(vbms_comm_package)
    package = ExternalApi::PacmanService.send_communication_package_request(vbms_comm_package.file_number,
                                                                            vbms_comm_package.comm_package_name,
                                                                            vbms_comm_package.document_referenced)
    distribution = ExternalApi::PacmanService.send_distribution_request(package_id, recipient, destinations)
  end
end
