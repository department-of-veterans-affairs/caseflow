# frozen_string_literal: true

class HearingAdmin < Organization
  def self.singleton
    HearingAdmin.first || HearingAdmin.create(name: "Hearing Admin", url: "hearing-admin")
  end
end
