# frozen_string_literal: true

class MailRecipient
  attr_reader :name, :email, :title

  RECIPIENT_TITLES = {
    judge: "Judge",
    veteran: "Veteran",
    representative: "Representative"
  }.freeze

  def initialize(name:, email:, title: nil)
    @name = name
    @email = email
    @title = title
  end
end
