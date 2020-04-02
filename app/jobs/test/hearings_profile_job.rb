# frozen_string_literal: true

class Test::HearingsProfileJob < ApplicationJob
  queue_with_priority :low_priority

  def perform(send_to_user, *args)
    options = args.extract_options!
    # don't go over 20 of each appeal type for email
    options[:limit] = [options[:limit], 20].min if options[:limit].present?
    Test::HearingsProfileMailer.call(
      email_address: send_to_user.email,
      mail_body: Test::HearingsProfileHelper.profile_data(send_to_user, **options).to_json
    ).deliver_now!

    Rails.logger.info("Sent hearings profile email to #{send_to_user.email}!")
  end
end
