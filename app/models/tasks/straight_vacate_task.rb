# frozen_string_literal: true

class StraightVacateTask < DecidedMotionToVacateTask
  class << self
    def label
      COPY::STRAIGHT_VACATE_TASK_LABEL
    end

    def org(user)
      JudgeTeam.for_judge(user.reload)
    end
  end
end
