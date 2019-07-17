# frozen_string_literal: true

class ExtraordinaryCaseAdvancementTeam < Organization
  def self.singleton
    ExtraordinaryCaseAdvancementTeam.first || ExtraordinaryCaseAdvancementTeam.create(name: "Case Movement Team", url: "eca")
  end
end
