# frozen_string_literal: true

class VirtualHearingUserAlertGenerator
  attr_accessor :created, :emails_sent_updates, :status, :veteran_full_name

  def initialize(created:, emails_sent_updates:, status:, veteran_full_name:)
    @created = created
    @status = status
    @emails_sent_updates = emails_sent_updates
    @veteran_full_name = veteran_full_name
  end

  def call
    UserAlert.new(title: title, message: message, type: UserAlert::TYPES[:info])
  end

  private

  def title
    copy["TITLE"] % veteran_full_name
  end

  def message
    return email_message if emails_updated?

    copy["MESSAGE"]
  end

  def copy
    if status == "cancelled"
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_FROM_VIRTUAL"]
    elsif created
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_TO_VIRTUAL"]
    elsif emails_updated?
      COPY::VIRTUAL_HEARING_USER_ALERTS["EMAILS_UPDATED"]
    end
  end

  def email_message
    if !emails_sent_updates[:veteran_email] && !emails_sent_updates[:representative_email]
      copy["MESSAGES"]["TO_VETERAN_AND_POA"]
    elsif !emails_sent_updates[:veteran_email]
      copy["MESSAGES"]["TO_VETERAN"]
    elsif !emails_sent_updates[:representative_email]
      copy["MESSAGES"]["TO_POA"]
    end
  end

  def emails_updated?
    (!emails_sent_updates[:veteran_email] || !emails_sent_updates[:representative_email]) &&
      status != "cancelled" && !created
  end
end
