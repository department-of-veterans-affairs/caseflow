# frozen_string_literal: true

class VirtualHearingUserAlertBuilder
  def initialize(change_type:, alert_type:, hearing:)
    @change_type = change_type
    @alert_type = alert_type
    @hearing = hearing
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[alert_type])
  end

  private

  attr_reader :change_type, :alert_type, :hearing

  def title
    copy["TITLE"] % (hearing.appeal.veteran&.name || "the veteran")
  end

  def message
    appellant_title = hearing.appeal.appellant_is_not_veteran ? "Appellant" : "Veteran"

    recipients = appellant_title.dup
    recipients << ", POA / Representative" if hearing.virtual_hearing.representative_email.present?
    recipients << ", and VLJ" if hearing.virtual_hearing.judge_email.present?

    recipients_except_vlj = appellant_title.dup
    recipients_except_vlj << " and POA / Representative" if hearing.virtual_hearing.representative_email.present?

    format(
      copy["MESSAGE"],
      appellant_title: appellant_title,
      recipients: recipients,
      recipients_except_vlj: recipients_except_vlj
    )
  end

  def copy
    if alert_type == :info
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]
    elsif alert_type == :success
      COPY::VIRTUAL_HEARING_SUCCESS_ALERTS[change_type]
    else
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: alert_type,
        message: "Alert type is invalid"
      )
    end
  end
end
