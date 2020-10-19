# frozen_string_literal: true

class CavcLitigationSupport < Organization
  def self.singleton
    CavcLitigationSupport.first ||
      CavcLitigationSupport.create(name: "CAVC Litigation Support", url: "cavc-lit-support")
  end

  def users_can_create_mail_task?
    true
  end
end
