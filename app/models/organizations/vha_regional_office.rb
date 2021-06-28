# frozen_string_literal: true

class VhaRegionalOffice < Organization
  def self.singleton
    VhaRegionalOffice.first || VhaRegionalOffice.create(name: "VHA Regional Office", url: "vha-regional-office")
  end
end
