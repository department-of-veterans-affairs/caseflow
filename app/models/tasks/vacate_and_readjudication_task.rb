# frozen_string_literal: true

class VacateAndReadjudicationTask < DecidedMotionToVacateTask
  class << self
    def label
      COPY::VACATE_AND_READJUDICATION_TASK_LABEL
    end

    def org(user)
      team = JudgeTeam.for_judge(user.reload)

      fail(Caseflow::Error::NonexistentJudgeTeam, user_id: user.id) if team.nil?

      team
    end
  end
end
