# frozen_string_literal: true

class HearingEmailStatusMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "hearing_email_status_mailer"
  helper VirtualHearings::LinkHelper
  include Hearings::AppellantNameHelper
  include Hearings::CalendarTemplateHelper

  def notification(sent_hearing_email_event:)
    @sent_hearing_email_event = sent_hearing_email_event

    # Extract each piece of data the templates use
    @hearing = @sent_hearing_email_event.hearing
    @hearing_type = Constants::HEARING_REQUEST_TYPES.key(@hearing.request_type).titleize
    @email_type = @sent_hearing_email_event.email_type.downcase
    @email_address = @sent_hearing_email_event.email_address
    @veteran_name = formatted_appellant_name(@hearing.appeal)
    @hearing_date = Hearings::CalendarTemplateHelper.hearing_date_only(@hearing)

    mail(
      to: @sent_hearing_email_event.email_address,
      subject: notification_subject
    )
  end

  def notification_subject
    "#{@hearing_type} #{@email_type} email failed to send to #{@email_address}"
  end
end
