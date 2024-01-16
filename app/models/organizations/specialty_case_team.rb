# frozen_string_literal: true

# The Spcialty Case Team

class SpecialtyCaseTeam < Organization
  def self.singleton
    SpecialtyCaseTeam.first || SpecialtyCaseTeam.create(name: "Specialty Case Team", url: "specialty-case-team")
  end

  def can_receive_task?(_task)
    false
  end
end
