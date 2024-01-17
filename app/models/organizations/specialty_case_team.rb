# frozen_string_literal: true

# The Spcialty Case Team
# An appeal is routed to this organization when both of the following are true:
#   - Veterans Health Administration (VHA) is selected as the benefit type
#   - VHA issues are added during the intake of an appeal
# The appeal is to be routed following appeal distribution request

class SpecialtyCaseTeam < Organization
  def self.singleton
    SpecialtyCaseTeam.first || SpecialtyCaseTeam.create(name: "Specialty Case Team", url: "specialty-case-team")
  end

  def can_receive_task?(_task)
    false
  end
end
