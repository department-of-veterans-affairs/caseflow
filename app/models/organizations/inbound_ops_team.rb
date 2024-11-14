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

  # inbound ops can only work Correspondence Tasks
  # inbound ops cannot work tasks not related to an appeal
  def can_receive_task?(_task)
    return false unless task.is_a?(CorrespondenceTask)

    !CorrespondenceTask.tasks_not_related_to_an_appeal_names.include?(task.class.name)
  end
end
