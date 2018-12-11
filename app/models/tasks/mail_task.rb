class MailTask < GenericTask
  class << self
    def create_from_params(params, user)
      verify_user_can_assign!(user)

      root_task = RootTask.find(params[:parent_id])
      unless root_task
        fail(Caseflow::Error::NoRootTask, message: "Could not find root task for appeal with ID #{params[:appeal]}")
      end

      mail_task = create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )

      # Create a child task off of the mail organization's task so we can track how that task was created.
      create_child_task(mail_task, user, params)
    end

    def create_child_task(parent, user, params)
      parent.update!(status: Constants.TASK_STATUSES.on_hold)

      Task.create!(
        type: name,
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, user),
        parent_id: parent.id,
        assigned_to: assignee,
        instructions: params[:instructions]
      )
    end

    def verify_user_can_assign!(user)
      unless MailTeam.singleton.user_has_access?(user)
        fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot create a mail task"
      end
    end
  end

  def label
    self.class.label
  end
end

# TODO: Add more subclasses
# TODO: Flesh out routing rules based on status of appeal.
# TODO: Register these subclasses with the main mail task.
# TODO: Ignore multiple tasks of same type error.
class AddressChangeMailTask < MailTask
  class << self
    def label
      "Change of address"
    end

    def assignee
      Colocated.singleton
    end
  end
end

class EvidenceOrArgumentMailTask < MailTask
  class << self
    def label
      "Evidence or argument"
    end

    def assignee
      Colocated.singleton
    end
  end
end

class PowerOfAttorneyRelatedMailTask < MailTask
  class << self
    def label
      "Power of attorney-related"
    end

    def assignee
      Colocated.singleton
    end
  end
end
