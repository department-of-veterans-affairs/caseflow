# frozen_string_literal: true

class VirtualHearingUserAlertBuilder
  attr_accessor :change_type, :alert_type, :veteran_full_name

  def initialize(change_type:, alert_type:, veteran_full_name:)
    @change_type = change_type
    @alert_type = alert_type
    @veteran_full_name = veteran_full_name
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[alert_type], auto_clear: false)
  end

  private

  def title
    copy["TITLE"] % veteran_full_name
  end

  def message
    copy["MESSAGE"]
  end

  def copy
    if alert_type == :info
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS[change_type]
    elsif alert_type == :success
      COPY::VIRTUAL_HEARING_SUCCESS_ALERTS[change_type]
    end
  end
end
