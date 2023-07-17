# frozen_string_literal: true

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

  def verify_request_type_designated
    if type == "HearingRequestMailTask"
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
  end
end
