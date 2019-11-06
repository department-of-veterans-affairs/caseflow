# frozen_string_literal: true

class StraightVacateAndReadjudicationTask < DecidedMotionToVacateTask
  def self.label
    COPY::STRAIGHT_VACATE_AND_READJUDICATION_TASK_LABEL
  end

  def self.org(user)
    JudgeTeam.for_judge(user.reload)
  end
end
