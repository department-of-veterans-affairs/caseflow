# frozen_string_literal: true

class Camo < Organization
  def self.singleton
    Camo.first || Camo.create(name: "CAMO", url: "camo")
  end
end
