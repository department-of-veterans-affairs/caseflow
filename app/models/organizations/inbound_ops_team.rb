# frozen_string_literal: true

class InboundOpsTeam < Organization
  def self.singleton
    InboundOpsTeam.first ||
      InboundOpsTeam.create(name: "Inbound Ops Team", url: "inbound-ops-team")
  end

  # :reek:UtilityFunction
  def selectable_in_queue?
    FeatureToggle.enabled?(:correspondence_queue, user: RequestStore.store[:current_user])
  end
end
