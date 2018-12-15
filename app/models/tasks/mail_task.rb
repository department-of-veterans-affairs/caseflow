class MailTask < GenericTask
  # Skip unique verification for mail tasks since multiple mail tasks of each type can be created.
  def verify_org_task_unique; end

  class << self
    def subclasses
      [
        AddressChangeMailTask,
        EvidenceOrArgumentMailTask,
        PowerOfAttorneyRelatedMailTask
      ]
    end

    def subclass_routing_options
      MailTask.subclasses.map { |subclass| { value: subclass.name, label: subclass.label } }
    end

    # TODO: Put this whole thing in a transaction so if we fail to create any of the child tasks, we don't create any.
    def create_from_params(params, user)
      verify_user_can_create!(user)

      root_task = RootTask.find(params[:parent_id])
      unless root_task
        fail(Caseflow::Error::NoRootTask, message: "Could not find root task for appeal with ID #{params[:appeal]}")
      end

      # Create a task assigned to the mail organization with a child task so we can track how that child was created.
      mail_task = create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )

      create_child_task(mail_task, user, params)
    end

    def verify_user_can_create!(user)
      unless MailTeam.singleton.user_has_access?(user)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot create a mail task"
      end
    end
  end

  def label
    self.class.label
  end
end

class ColocatedMailTask < MailTask
  include RoundRobinAssigner

  class << self
    def latest_task
      Task.where(assigned_to_type: User.name, assigned_to_id: [assignee_pool.pluck(:id)]).order("created_at").last
    end

    def assignee_pool
      Colocated.singleton.non_admins.sort_by(&:id)
    end

    def list_of_assignees
      assignee_pool.pluck(:css_id)
    end

    # TODO: This seems a little inefficient. We're effectively replicating GenericTask.create_child_task.
    # Can we do better?
    def create_child_task(parent, user, params)
      parent.update_status(Constants.TASK_STATUSES.on_hold)

      vlj_support_org_task = Task.create!(
        type: name,
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, user),
        parent_id: parent.id,
        assigned_to: Colocated.singleton,
        instructions: params[:instructions]
      )

      super(vlj_support_org_task, user, params)
    end

    def get_child_task_assignee(_params)
      next_assignee
    end
  end
end

# TODO: Flesh out routing rules based on status of appeal.
class AddressChangeMailTask < ColocatedMailTask
  class << self
    def label
      COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
    end
  end
end

class EvidenceOrArgumentMailTask < ColocatedMailTask
  class << self
    def label
      COPY::EVIDENCE_OR_ARGUMENT_MAIL_TASK_LABEL
    end
  end
end

class PowerOfAttorneyRelatedMailTask < ColocatedMailTask
  class << self
    def label
      COPY::POWER_OF_ATTORNEY_MAIL_TASK_LABEL
    end
  end
end
