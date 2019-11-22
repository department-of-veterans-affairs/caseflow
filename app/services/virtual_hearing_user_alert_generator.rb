# frozen_string_literal: true

class VirtualHearingUserAlertGenerator
  attr_accessor :created, :virtual_hearing_attributes, :veteran_full_name

  def initialize(created:, virtual_hearing_attributes:, veteran_full_name:)
    @created = created
    @virtual_hearing_attributes = virtual_hearing_attributes
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
    return email_message if only_emails_updated?

    copy["MESSAGE"]
  end

  def copy
    if only_emails_updated?
      COPY::VIRTUAL_HEARING_USER_ALERTS["EMAILS_UPDATED"]
    elsif cancelled?
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_FROM_VIRTUAL"]
    elsif created
      COPY::VIRTUAL_HEARING_USER_ALERTS["HEARING_CHANGED_TO_VIRTUAL"]
    end
  end

  def email_message
    if virtual_hearing_attributes.key?(:veteran_email) && virtual_hearing_attributes.key?(:representative_email)
      copy["MESSAGES"]["TO_VETERAN_AND_POA"]
    elsif virtual_hearing_attributes.key?(:veteran_email)
      copy["MESSAGES"]["TO_VETERAN"]
    elsif virtual_hearing_attributes.key?(:representative_email)
      copy["MESSAGES"]["TO_POA"]
    end
  end

  def cancelled?
    virtual_hearing_attributes[:status] == "cancelled"
  end

  def only_emails_updated?
    (virtual_hearing_attributes.key?(:veteran_email) || virtual_hearing_attributes.key?(:representative_email)) &&
      !cancelled? && !created
  end
end
