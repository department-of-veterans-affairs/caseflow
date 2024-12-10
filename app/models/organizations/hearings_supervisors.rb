# frozen_string_literal: true

class HearingsSupervisors < Organization
  def self.singleton
    HearingsSupervisors.first || HearingsSupervisors.create(name: "Hearings Supervisors", url: "hearings-supervisors")
  end

  def can_receive_task?
    false
  end
end
