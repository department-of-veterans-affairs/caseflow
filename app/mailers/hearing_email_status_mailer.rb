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
    @hearing = sent_hearing_email_event.hearing
    @hearing_type = sent_hearing_email_event.hearing.hearing_request_type
    # Email types are: "confirmation", "cancellation", "updated_time_confirmation", "reminder"
    # The gsub is so that "updated_time_confirmation" shows as "Updated Time Confirmation"
    @email_type = sent_hearing_email_event.email_type.tr("_", " ").downcase
    @email_address = sent_hearing_email_event.email_address
    @recipient_role = sent_hearing_email_event.recipient_role
    @veteran_name = formatted_appellant_name(sent_hearing_email_event.hearing.appeal)
    @hearing_date = Hearings::CalendarTemplateHelper.hearing_date_only(sent_hearing_email_event.hearing)

    mail(
      to: @sent_hearing_email_event.sent_by&.email,
      subject: notification_subject
    )
  end

  def notification_subject
    "#{@hearing_type} #{@email_type} email failed to send to #{@email_address}"
  end
end
