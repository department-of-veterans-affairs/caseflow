# frozen_string_literal: true

class VirtualHearingUserAlertGenerator
  attr_accessor :create, :email_sent_update, :status, :veteran_full_name

  def initialize(created:, email_sent_update:, status:, veteran_full_name:)
    @created = created
    @status = status
    @email_sent_update = email_sent_update
    @veteran_full_name = veteran_full_name
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[:info])
  end

  private

  def title
    copy::TITLE % veteran_full_name
  end

  def message
    return email_message if emails_updated?

    copy["MESSAGE"]
  end

  def copy
    if status == "cancelled"
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGE_FROM_VIRTUAL"]
    elsif created
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGE_TO_VIRTUAL"]
    elsif emails_updated?
      COPY::VIRTUAL_HEARING_USER_ALERTS["EMAILS_UPDATED"]
    end
  end

  def email_message
    if !email_sent_update[:veteran_email] && !email_sent_update[:representative_email]
      copy["MESSAGES"]["TO_VETERAN_AND_POA"]
    elsif !email_sent_update[:veteran_email]
      copy["MESSAGES"]["TO_VETERAN"]
    elsif !email_sent_update[:representative_email]
      copy["MESSAGES"]["TO_POA"]
    end
  end

  def emails_updated?
    !email_sent_update[:veteran_email] || !email_sent_update[:representative_email]
  end
end
