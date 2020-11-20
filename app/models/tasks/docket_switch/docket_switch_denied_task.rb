# frozen_string_literal: true

class DocketSwitchDeniedTask < DocketSwitchAttorneyTask
  class << self
    def label
      COPY::DOCKET_SWITCH_DENIED_TASK_LABEL
    end

    def task_action
      Constants.TASK_ACTIONS.DOCKET_SWITCH_DENIED.to_h
    end
  end
end
