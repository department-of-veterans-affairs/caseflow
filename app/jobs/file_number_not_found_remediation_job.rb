# frozen_string_literal: true

class FileNumberNotFoundRemediationJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform
    RequestStore[:current_user] = User.system_user

    FileNumberNotFoundFix.new.perform
  rescue StandardError => error
    log_error(error)
  end
end
