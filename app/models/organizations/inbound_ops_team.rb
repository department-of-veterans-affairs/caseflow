# frozen_string_literal: true

class InboundOpsTeam < Organization
  def self.singleton
    InboundOpsTeam.first ||
      InboundOpsTeam.create(name: "Inbound Ops Team", url: "inbound-ops-team")
  end

  # :reek:UtilityFunction
  def selectable_in_queue?
    false
  end
end
