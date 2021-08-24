# frozen_string_literal: true

class HearingEmailStatusMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "hearing_email_status_mailer"
  helper VirtualHearings::LinkHelper
  helper Hearings::AppellantNameHelper

  def notification(sent_hearing_email_event:)
    @sent_hearing_email_event = sent_hearing_email_event

    # Make it easier for templates to access hearing information
    @hearing = @sent_hearing_email_event.hearing

    mail(
      to: @sent_hearing_email_event.email_address,
      subject: "Email Failed to Send - Do Not Reply"
    )
  end
end
