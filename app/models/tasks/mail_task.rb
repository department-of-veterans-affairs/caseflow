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

    def outstanding_cavc_tasks?(_parent)
      # We don't yet create CAVC tasks so this will always return false for now.
      false
    end

    def pending_hearing_task?(parent)
      # TODO: Update this function once AMA appeals start to be held (sometime after 14 FEB 19). Right now this expects
      # that every AMA appeal that is on the hearing docket has a pending hearing task.
      parent.appeal.hearing_docket?
    end

    def case_active?(parent)
      # TODO: I think this will always return true if we can create MailTasks since the creation of mail tasks relies
      # on the presence of an incomplete RootTask.
      parent.appeal.active?
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
      parent_colocated_task_already_created?(parent) ? next_assignee : Colocated.singleton
    end

    def parent_colocated_task_already_created?(parent)
      parent.is_a?(name.constantize) && parent.assigned_to == Colocated.singleton
    end
  end

  def create_grandchild_task
    self.class.create_child_task(self, nil, instructions: instructions)
  end

  def should_create_grandchild_task?
    assigned_to == Colocated.singleton
  end
end

class AddressChangeMailTask < ColocatedMailTask
  class << self
    def label
      COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL
    end

    def get_child_task_assignee(parent, params)
      return HearingsManagement.singleton if pending_hearing_task?(parent)
      return super if case_active?(parent)

      fail Caseflow::Error::MailRoutingError
    end
  end
end

class EvidenceOrArgumentMailTask < ColocatedMailTask
  class << self
    def label
      COPY::EVIDENCE_OR_ARGUMENT_MAIL_TASK_LABEL
    end

    def get_child_task_assignee(parent, params)
      return LitigationSupport.singleton if outstanding_cavc_tasks?(parent)
      return super if case_active?(parent)

      LitigationSupport.singleton
    end
  end
end

class PowerOfAttorneyRelatedMailTask < ColocatedMailTask
  class << self
    def label
      COPY::POWER_OF_ATTORNEY_MAIL_TASK_LABEL
    end

    def get_child_task_assignee(parent, params)
      return HearingsManagement.singleton if pending_hearing_task?(parent)
      return super if case_active?(parent)

      fail Caseflow::Error::MailRoutingError
    end
  end
end
