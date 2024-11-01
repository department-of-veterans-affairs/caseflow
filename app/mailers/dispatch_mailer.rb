# frozen_string_literal: true

##
# DispatchMailer will:
# - Generate emails from the templates in app/views/dispatch_mailer
##
# rubocop:disable Rails/ApplicationMailer
class DispatchMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsDecisions@messages.va.gov>"
  layout "dispatch_mailer"
  helper VirtualHearings::LinkHelper

  def dispatch(email_address:, appeal: nil)
    @appeal = appeal
    @appellant_name = appellant_name

    mail(
      to: email_address,
      subject: "Dispatched Decision for #{appellant_name} is ready for review – Do Not Reply"
    )
  end

  def appellant_name
    @appeal.appellant_or_veteran_name
  end
end
# rubocop:enable Rails/ApplicationMailer
