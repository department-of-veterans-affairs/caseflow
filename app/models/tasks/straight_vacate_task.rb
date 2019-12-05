# frozen_string_literal: true

class StraightVacateTask < DecidedMotionToVacateTask
  class << self
    def label
      COPY::STRAIGHT_VACATE_TASK_LABEL
    end

    def org(user)
      team = JudgeTeam.for_judge(user.reload)

      fail(Caseflow::Error::NonexistentJudgeTeam, user_id: user.id) if team.nil?

      team
    end
  end
end
