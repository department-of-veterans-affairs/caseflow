# frozen_string_literal: true

class VacateAndReadjudicationTask < DecidedMotionToVacateTask
  class << self
    def label
      COPY::VACATE_AND_READJUDICATION_TASK_LABEL
    end

    def org(user)
      JudgeTeam.for_judge(user.reload)
    end
  end
end
