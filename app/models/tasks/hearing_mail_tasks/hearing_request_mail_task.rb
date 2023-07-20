# frozen_string_literal: true

##
# Task to serve as interface with shared methods for the following hearings mail tasks:
#   - HearingPostponementRequestMailTask
#   - HearingWithdrawalRequestMailTask
# HearingRequestMailTask is itself not an assignable task type

class HearingRequestMailTask < MailTask
  validates :parent, presence: true, on: :create

  # Is this check necessary?
  #   - In theory you could call MailTask.create even though MailTask is not an assignable task
  before_validation :verify_request_type_designated

  class << self
    def allow_creation?(*)
      false
    end

    # All descendant postponement/withdrawal tasks will initially be assigned to the Hearing Admin org
    def default_assignee(_task)
      HearingAdmin.singleton
    end
  end

  def available_actions(_user)
    []
  end

  def update_from_params(params, current_user)
    super(params, current_user)
  end

  private

  # Ensure create is called on a descendant mail task and not directly on the HearingRequestMailTask class
  def verify_request_type_designated
    if self.class == HearingRequestMailTask
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
  end
end
