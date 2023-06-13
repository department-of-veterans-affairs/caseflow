# frozen_string_literal: true

class HearingRequestMailTask < MailTask
  validates :parent, presence: true, on: :create

  class << self
    def allow_creation?(*)
      false
    end

    def default_assignee(_task)
      # All Hearing X Request Mail tasks will be assigned to the Hearing Admin org initially
      HearingAdmin.singleton
    end
  end

  def available_actions
    []
  end

  def update_from_params(params, current_user)
    super(params, current_user)
  end
end
