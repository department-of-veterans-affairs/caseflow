# frozen_string_literal: true

class VirtualHearingUserAlertBuilder

  def initialize(change_type:, alert_type:, appeal:)
    @change_type = change_type
    @alert_type = alert_type
    @appeal = appeal
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[alert_type])
  end

  private

  attr_reader :change_type, :alert_type, :appeal

  def title
    copy["TITLE"] % (appeal.veteran.name || "the veteran")
  end

  def message
    appellant_title = appeal.appellant_is_not_veteran ? "Appellant" : "Veteran"

    copy["MESSAGE"] % { appellant_title: appellant_title }
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
