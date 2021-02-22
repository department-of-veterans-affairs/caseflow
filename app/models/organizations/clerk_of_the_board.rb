# frozen_string_literal: true

class ClerkOfTheBoard < Organization
  alias_attribute :full_name, :name

  def self.singleton
    ClerkOfTheBoard.first || ClerkOfTheBoard.create(name: "Clerk of the Board", url: "clerk-of-the-board")
  end

  def can_receive_task?(_task)
    false
  end

  def users_can_create_mail_task?
    true
  end
end
