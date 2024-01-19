# frozen_string_literal: true

# The Specialty Case Team (SCT)
#
# A single organization within the Board of Veteran Appeals (BVA).
# Established to increase efficiency in decision-writing for appeals with rare issues.
# Cases with rare issues are assigned to specific attorneys that specialize in particular legal topic areas.

class SpecialtyCaseTeam < Organization
  def self.singleton
    SpecialtyCaseTeam.first || SpecialtyCaseTeam.create(name: "Specialty Case Team", url: "specialty-case-team")
  end

  def can_receive_task?(_task)
    false
  end
end
