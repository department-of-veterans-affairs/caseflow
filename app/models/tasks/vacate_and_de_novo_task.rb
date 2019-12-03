# frozen_string_literal: true

class VacateAndDeNovoTask < DecidedMotionToVacateTask
  class << self
    def label
      COPY::VACATE_AND_DE_NOVO_TASK_LABEL
    end

    def org(user)
      JudgeTeam.for_judge(user.reload)
    end
  end
end
