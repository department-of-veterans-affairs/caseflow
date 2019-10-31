# frozen_string_literal: true

class VirtualHearings::DeleteConferencesJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    VirtualHearingRepository.ready_for_deletion.map do |virtual_hearing|
      delete_conference(virtual_hearing)
    end
  end

  private

  def pexip_service
    @service ||= PexipService.new(
      host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
      port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
      user_name: ENV["PEXIP_USERNAME"],
      password: ENV["PEXIP_PASSWORD"],
      client_host: ENV["PEXIP_CLIENT_HOST"]
    )
  end

  def delete_conference(virtual_hearing)
    service.delete_conference(conference_id: virtual_hearing.conference_id)
  rescue PexipNotFoundError
    virtual_hearing.conference_deleted = true
  rescue PexipApiError
    virtual_hearing.conference_deleted = true
  end
end
