# frozen_string_literal: true

class VhaProgramOffice < Organization
  def self.singleton
    VhaProgramOffice.first || VhaProgramOffice.create(name: "VHA PROGRAM OFFICE", url: "vha-program-office")
  end
end
