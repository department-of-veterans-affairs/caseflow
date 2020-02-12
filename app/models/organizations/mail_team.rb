# frozen_string_literal: true

class MailTeam < Organization
  def self.singleton
    MailTeam.first || MailTeam.create(name: "Mail", url: "mail")
  end

  def users_can_create_mail_task?
    true
  end
end
