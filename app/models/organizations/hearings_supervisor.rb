# frozen_string_literal: true

class HearingsSupervisor < Organization
  def self.singleton
    HearingsSupervisor.first || HearingsSupervisor.create(name: "Hearings Supervisor", url: "hearings-supervisors")
  end

  def can_receive_task?(task)
    #this will be implemented in the future
    false
  end
end
