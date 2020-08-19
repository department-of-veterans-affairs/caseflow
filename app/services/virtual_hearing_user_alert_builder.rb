# frozen_string_literal: true

class VirtualHearingUserAlertBuilder
  def initialize(change_type:, alert_type:, appeal:, virtual_hearing_updates:)
    @change_type = change_type
    @alert_type = alert_type
    @appeal = appeal
    @virtual_hearing_updates = virtual_hearing_updates
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[alert_type])
  end

  private

  attr_reader :change_type, :alert_type, :appeal, :virtual_hearing_updates

  def title
    copy["TITLE"] % (appeal.veteran&.name || "the veteran")
  end

  def message
    recipients = []

    unless virtual_hearing_updates.fetch(:appellant_email_sent, true)
      appellant_title = appeal.appellant_is_not_veteran ? "Appellant" : "Veteran"
      recipients << appellant_title
    end

    unless virtual_hearing_updates.fetch(:representative_email_sent, true)
      recipients << "POA / Representative"
    end

    unless virtual_hearing_updates.fetch(:judge_email_sent, true)
      judge = recipients.empty? ? "VLJ" : "and VLJ" 
      recipients << judge 
    end

    format(
      copy["MESSAGE"],
      appellant_title: appellant_title,
      recipients: recipients.join(recipients.size > 2 ? ", " : " and ")
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
