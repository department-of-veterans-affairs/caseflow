# frozen_string_literal: true

class MailRecipient
  attr_reader :first_name, :last_name, :email, :title

  def initialize(first_name:, last_name:, email:, title: nil)
    @first_name = first_name
    @last_name = last_name
    @email = email
    @title = title
  end
end
