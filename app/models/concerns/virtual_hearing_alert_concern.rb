# frozen_string_literal: true

module VirtualHearingAlertConcern
  extend ActiveSupport::Concern

  def only_emails_updated?
    email_changed = virtual_hearing_attributes.key?(:veteran_email) ||
                    virtual_hearing_attributes.key?(:representative_email) ||
                    virtual_hearing_attributes.key?(:judge_email)

    email_changed && !virtual_hearing_cancelled? && !virtual_hearing_created?
  end

  def email_change_type
    if virtual_hearing_attributes.key?(:veteran_email) && virtual_hearing_attributes.key?(:representative_email)
      "CHANGE_VETERAN_AND_POA_EMAIL"
    elsif virtual_hearing_attributes.key?(:veteran_email)
      "CHANGE_VETERAN_EMAIL"
    elsif virtual_hearing_attributes.key?(:representative_email)
      "CHANGE_POA_EMAIL"
    end
  end

  def virtual_hearing_cancelled?
    virtual_hearing_attributes[:status] == "cancelled"
  end

  def change_type
    if virtual_hearing_created?
      "CHANGE_TO_VIRTUAL"
    elsif virtual_hearing_cancelled?
      "CHANGE_FROM_VIRTUAL"
    elsif only_time_updated?
      "CHANGE_HEARING_TIME"
    elsif only_emails_updated?
      email_change_type
    end
  end

  def add_virtual_hearing_alerts
    # add in-progress alert
    alerts << VirtualHearingUserAlertBuilder.new(
      change_type: change_type,
      alert_type: :info,
      veteran_full_name: veteran_full_name
    ).call.to_hash

    # add success alert
    alerts << VirtualHearingUserAlertBuilder.new(
      change_type: change_type,
      alert_type: :success,
      veteran_full_name: veteran_full_name
    ).call.to_hash
  end
end