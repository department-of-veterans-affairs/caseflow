# frozen_string_literal: true

class InboundOpsTeam < Organization
  class << self
    def singleton
      InboundOpsTeam.first ||
        InboundOpsTeam.create(name: "Inbound Ops Team", url: "inbound-ops-team")
    end

    def super_users
      super_users = []

      OrganizationsUser.includes(:user).where(organization: InboundOpsTeam.singleton).find_each do |org_user|
        user = org_user.user

        if user.inbound_ops_team_superuser?
          super_users.push(user)
        end
      end

      super_users
    end
  end

  # :reek:UtilityFunction
  def selectable_in_queue?
    false
  end

  def can_receive_task?(task)
    return false if task.assigned_to == self
    return false if task.assigned_to.is_a?(User) && task.parent && task.parent.assigned_to == self
  end
end
