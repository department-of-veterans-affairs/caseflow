# frozen_string_literal: true

##
# Interface for:
#   - HearingPostponementRequestMailTask
#   - HearingWithdrawalRequestMailTask
# HearingRequestMailTask is itself not an assignable task type

class HearingRequestMailTask < MailTask
  validates :parent, presence: true, parentTask: { task_type: HearingTask }, on: :create

  before_create :verify_request_type_designated

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

  private

  # Ensure #create is called on a descendant class
  def verify_request_type_designated
    valid_request_types = %w[HearingPostponementRequestMailTask HearingWithdrawalRequestMailTask]

    unless valid_request_types.include?(type)
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
  end
end
