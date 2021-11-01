# frozen_string_literal: true

class VirtualHearingUserAlertBuilder
  def initialize(change_type:, alert_type:, hearing:, virtual_hearing_updates:)
    @change_type = change_type
    @alert_type = alert_type
    @hearing = hearing
    @virtual_hearing_updates = virtual_hearing_updates
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[alert_type])
  end

  private

  attr_reader :change_type, :alert_type, :hearing, :virtual_hearing_updates

  def title
    copy["TITLE"] % (hearing.appeal.veteran&.name || "the veteran")
  end

  def appellant_title
    hearing.appeal.appellant_is_not_veteran ? "Appellant" : "Veteran"
  end

  # Appellant is a recipient if the `appellant_email_sent` flag is changing.
  def appellant_is_recipient?
    virtual_hearing_updates.key?(:appellant_email_sent)
  end

  # POA / Representative is a recipient if the `representative_email_sent` flag is
  # changing, and there is a `representative_email` stored.
  def representative_is_recipient?
    virtual_hearing_updates.key?(:representative_email_sent) &&
      hearing.virtual_hearing.representative_email.present?
  end

  # VLJ is a recipient if the `judge_email_sent` flag is changing, and there
  # is a `judge_email` stored.
  def vlj_is_recipient?
    virtual_hearing_updates.key?(:judge_email_sent) &&
      hearing.virtual_hearing.judge_email.present?
  end

  def message
    recipients = []
    recipients_except_vlj = []

    if appellant_is_recipient?
      recipients << appellant_title
      recipients_except_vlj << appellant_title
    end

    if representative_is_recipient?
      recipients << "POA / Representative"
      recipients_except_vlj << "POA / Representative"
    end

    if vlj_is_recipient?
      recipients << "VLJ"
    end

    format(
      copy["MESSAGE"],
      appellant_title: appellant_title,
      recipients: recipients.to_sentence,
      recipients_except_vlj: recipients_except_vlj.to_sentence
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
