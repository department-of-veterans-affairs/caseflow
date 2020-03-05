# frozen_string_literal: true

class Test::HearingsProfileMailer < ActionMailer::Base
  default from: "solutions@public.govdelivery.com"

  def call(email_address:, mail_body:)
    # format "Mar 4 at 16:02"
    timestamp = Time.zone.now.strftime("%b %-d at %H:%M")

    mail(
      to: email_address,
      subject: "Hearings profile results on #{timestamp}",
      body: mail_body,
      content_type: "text/plain"
    )
  end
end
