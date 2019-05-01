# frozen_string_literal: true

class LitigationSupport < Organization
  def self.singleton
    LitigationSupport.first || LitigationSupport.create(name: Constants.LIT_SUPPORT.ORG_NAME, url: "lit-support")
  end
end
