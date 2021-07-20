# frozen_string_literal: true

class EmailRecipientInfo
  attr_reader :name, :email, :title, :hearing_email_recipient

  def initialize(name:, title:, hearing_email_recipient:)
    @name = name
    @title = title
    @email = hearing_email_recipient&.email_address
    @hearing_email_recipient = hearing_email_recipient
  end
end
