# frozen_string_literal: true

class DuplicateEpRemediationJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :intake
  def perform
    RequestStore[:current_user] = User.system_user

    WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new.resolve_dup_ep
  rescue StandardError => error
    log_error(error)
  end
end
