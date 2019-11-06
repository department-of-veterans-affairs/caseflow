# frozen_string_literal: true

class StraightVacateAndReadjudicationTask < DecidedMotionToVacateTask
  def self.label
    COPY::STRAIGHT_VACATE_AND_READJUDICATION_TASK_LABEL
  end

  def self.org(_user)
    JudgeTeam.for_judge(_user.reload)
  end
end
