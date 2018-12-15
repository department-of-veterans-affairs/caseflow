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

      params = modify_params(params)
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

  after_update :create_grandchild_task, if: :should_create_grandchild_task?

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

    def get_child_task_assignee(parent, _params)
      (parent.is_a?(name.constantize) && parent.assigned_to == Colocated.singleton) ? next_assignee : Colocated.singleton
    end
  end

  def create_grandchild_task
    self.class.create_child_task(self, nil, instructions: instructions)
  end

  def should_create_grandchild_task?
    assigned_to == Colocated.singleton
  end
end

# Appeal statuses:
# Inactive - No RootTask or RootTask is complete... Will we show MailTask dropdown in either of these cases?
# Active - Incomplete RootTask
# Pending hearing - Open hearing task
# Pending CAVC response - Outstanding CAVC tasks

# TODO: Flesh out routing rules based on status of appeal.
# TODO: Which step of the assignment process do we hijack to apply the conditional routing stuff? Maybe we subclass
# create_from_params and then call super() on the class we want this to be routed to?
#
# Can we have each mail task subclass define a routing rules hierarchy that loops over the rules until one returns
# true and we route
class AddressChangeMailTask < ColocatedMailTask
  # Pending hearing -> Hearings branch
  # Active -> VLJ support
  # Inactive -> No task created. Throw error that explains what to do.
  class << self
    def label
      COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
    end

    def routing_rules
      [
        route_to_hearings_branch_if_open_hearings
      ]
    end

    def get_child_task_assignee(_parent, params)
      root_task = RootTask.find(params[:parent_id])

      # TODO: Don't do the Colocated round robin assignment stuff here.
      return HearingsManagement.singleton if root_task.appeal.tasks.where(type: ScheduleHearingsTask.name).where.not(status: Constants.TASK_STATUSES.completed).any?

      # TODO: Can I just call ColocatedMailTask.create_child_task() here? Or something like this?
      return Colocated.singleton if root_task.status != Constants.TASK_STATUSES.completed

      fail Caseflow::Error::MailRoutingError, "Appeal is not active at the Board. Send mail to appropriate Regional Office in mail portal"
    end
  end
end

class EvidenceOrArgumentMailTask < ColocatedMailTask
  # Pending CAVC response -> Lit Support
  # Active -> VLJ support
  # Inactive -> Lit Support
  class << self
    def label
      COPY::EVIDENCE_OR_ARGUMENT_MAIL_TASK_LABEL
    end
  end
end

class PowerOfAttorneyRelatedMailTask < ColocatedMailTask
  # Pending hearing -> Hearings branch
  # Active -> VLJ support
  # Inactive -> No task created. Throw error that explains what to do.
  class << self
    def label
      COPY::POWER_OF_ATTORNEY_MAIL_TASK_LABEL
    end
  end
end
