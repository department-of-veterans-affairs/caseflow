# frozen_string_literal: true

class SpecialCaseMovementTeam < Organization
  def self.singleton
    SpecialCaseMovementTeam.first || SpecialCaseMovementTeam.create(name: "Case Movement", url: "case-movement")
  end
end
