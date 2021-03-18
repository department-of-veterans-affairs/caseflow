# frozen_string_literal: true

class DocketSwitchGrantedTask < DocketSwitchAbstractAttorneyTask
  class << self
    def label
      COPY::DOCKET_SWITCH_GRANTED_TASK_LABEL
    end

    def task_action
      Constants.TASK_ACTIONS.DOCKET_SWITCH_GRANTED.to_h
    end
  end
end
