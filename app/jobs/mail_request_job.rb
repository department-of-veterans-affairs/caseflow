# frozen_string_literal: true

# This job syncs an EndProductEstablishment (end product manager) with up to date BGS and VBMS data
class MailRequestJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(vbms_comm_package)
    ExternalApi::
  end
end
