# frozen_string_literal: true

class ExtraodinaryCaseAdvancementTeam < Organization
  def self.singleton
    ExtroadinaryCaseAdvancementTeam.first || ExtraodinaryCaseAdvancementTeam.create(name: "ExtroadinaryCaseAdvancement", url: "eca")
  end
end
