# frozen_string_literal: true

class DocketSwitchMailTask < MailTask
  def available_actions(user)
    default_actions = super(user)
    actions = []

    if ClerkOfTheBoard.singleton.user_has_access?(user)
      actions += default_actions
      if assigned_to.is_a?(User) && FeatureToggle.enabled?(:docket_switch, user: user)
        actions.push(Constants.TASK_ACTIONS.DOCKET_SWITCH_SEND_TO_JUDGE.to_h)
      end
    end

    actions
  end

  def timeline_title
    COPY::DOCKET_SWITCH_MAIL_TASK_TITLE
  end

  class << self
    def label
      COPY::DOCKET_SWITCH_MAIL_TASK_LABEL
    end

    def create_from_params(params, user)
      parent_task = DistributionTask.find_by(appeal_id: params[:appeal].id)
      # binding.pry

      verify_user_can_create!(user, parent_task)

      transaction do
        if parent_task.is_a?(DistributionTask)
          # Create a task assigned to the mail team with a child task so we can track how that child was created.
          parent_task = create!(
            appeal: parent_task.appeal,
            parent_id: parent_if_blocking_task(parent_task).id,
            assigned_to: ClerkOfTheBoard.singleton,
            instructions: [params[:instructions]].flatten
          )
        end

        # distribution_task.update!(status: :on_hold)

        if child_task_assignee(parent_task, params).eql? ClerkOfTheBoard.singleton
          parent_task
        else
          params = modify_params_for_create(params)
          create_child_task(parent_task, user, params)
        end
      end
    end

    def allow_creation?(user:, appeal:)
      ClerkOfTheBoard.singleton.user_has_access?(user) && !appeal.outcoded?
    end

    # This differs from the default behavior of `MailTask`
    # Here we automatically assign the new task to the user that created it
    # They can reassign if need be, but this covers normal use cases
    def child_task_assignee(parent, params)
      if [:assigned_to_type, :assigned_to_id].all? { |key| params.key?(key) }
        super
      elsif (parent.type == DocketSwitchMailTask.name) && RequestStore[:current_user]
        RequestStore[:current_user]
      else
        ClerkOfTheBoard.singleton
      end
    end
  end
end
