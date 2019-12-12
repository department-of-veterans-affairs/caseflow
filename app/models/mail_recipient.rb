# frozen_string_literal: true

class MailRecipient
  attr_reader :name, :email, :title

  def initialize(name:, email:, title: nil)
    @name = name
    @email = email
    @title = title
  end
end
