# frozen_string_literal: true

class Test::HearingsProfileJob < ApplicationJob
  queue_with_priority :low_priority

  def perform(send_to_user:)
    HearingsProfileMailer.call(
      email_address: send_to_user.email,
      mail_body: HearingsProfileHelper.profile_data(send_to_user).to_json
    ).deliver_now

    Rails.logger.info("Sent hearings profile email to #{send_to_user.email}!")
  end
end
