# frozen_string_literal: true

class DocketSwitchDeniedTask < DocketSwitchAbstractAttorneyTask
  after_save :process!

  def process!
    close_ruling_task if active?
  end

  class << self
    def label
      COPY::DOCKET_SWITCH_DENIED_TASK_LABEL
    end

    def task_action
      Constants.TASK_ACTIONS.DOCKET_SWITCH_DENIED.to_h
    end
  end

  private

  def close_ruling_task
    parent.update(status: Constants.TASK_STATUSES.completed)
  end
end
