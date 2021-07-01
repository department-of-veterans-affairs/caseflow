# frozen_string_literal: true

class VhaCamo < Organization
  def self.singleton
    VhaCamo.first || VhaCamo.create(name: "VHA CAMO", url: "vha-camo")
  end
end
