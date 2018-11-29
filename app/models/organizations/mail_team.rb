class MailTeam < Organization
  def self.singleton
    MailTeam.first || MailTeam.create(name: "Mail", url: "mail")
  end
end
