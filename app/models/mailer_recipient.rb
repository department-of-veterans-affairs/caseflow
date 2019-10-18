# frozen_string_literal: true

class MailerRecipient
  attr_reader :full_name, :email, :title

  def initialize(full_name:, email:, title: nil)
    @full_name = full_name
    @email = email
    @title = title
  end
end
