# frozen_string_literal: true

class AodTeam < Organization
  def self.singleton
    AodTeam.first || AodTeam.create(name: "AOD", url: "aod")
  end
end
