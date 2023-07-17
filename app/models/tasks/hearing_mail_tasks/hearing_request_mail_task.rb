# frozen_string_literal: true

class HearingRequestMailTask < MailTask
  validates :parent, presence: true, parentTask: { task_type: HearingTask }, on: :create

  class << self
    def allow_creation?(*)
      false
    end

    def default_assignee(_task)
      HearingAdmin.singleton
    end

    def available_actions
      []
    end

    def update_from_params(params, current_user)
      super(params, current_user)
    end
  end
end
