# frozen_string_literal: true

class LitigationSupport < Organization
  def self.singleton
    LitigationSupport.first || LitigationSupport.create(name: "Litigation Support", url: "lit-support")
  end

  def users_can_create_mail_task?
    true
  end
end
