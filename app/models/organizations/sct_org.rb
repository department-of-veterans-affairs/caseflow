# frozen_string_literal: true

# organization representing the VHA Claims and Appeals Modernization Office

class SpecialtyCaseTeam < Organization
  def self.singleton
    SpecialtyCaseTeam.first || SpecialtyCaseTeam.create(name: "Specialty Case Team", url: "specialty-case-team")
  end
end
