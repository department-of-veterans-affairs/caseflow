# frozen_string_literal: true

class DocketSwitchGrantedTask < DocketSwitchAbstractAttorneyTask
  def timeline_title
    COPY::DOCKET_SWITCH_GRANTED_TASK_TITLE
  end

  class << self
    def label
      COPY::DOCKET_SWITCH_GRANTED_TASK_LABEL
    end

    def task_action
      Constants.TASK_ACTIONS.DOCKET_SWITCH_GRANTED.to_h
    end
  end
end
