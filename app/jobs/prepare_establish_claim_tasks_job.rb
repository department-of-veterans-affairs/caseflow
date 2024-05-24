# frozen_string_literal: true

class PrepareEstablishClaimTasksJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :dispatch

  def perform
    RequestStore.store[:current_user] = User.system_user

    prepare_establish_claims
  end

  def prepare_establish_claims
    count = { success: 0, fail: 0 }

    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    EstablishClaim.unprepared.each do |task|
      status = task.prepare_with_decision!
      count[:success] += ((status == :success) ? 1 : 0)
      count[:fail] += ((status == :failed) ? 1 : 0)
    end
    log_info(count) if count[:fail] > 0
  end

  def log_info(count)
    msg = "PrepareEstablishClaimTasksJob successfully ran: #{count[:success]} tasks " \
          "prepared and #{count[:fail]} tasks failed"
    Rails.logger.info msg
    SlackService.new.send_notification(msg)
  end
end
