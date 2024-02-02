# frozen_string_literal: true

class HearingTranscriptionMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "hearing_transciption_mailer"

  def vtt_to_rtf_conversion_error(msg)
    mail(
      to: "BVAHearingTeam@VA.gov",
      subject: "Error reported during VTT to RTF Conversion",
      body: msg
    )
  end
end
