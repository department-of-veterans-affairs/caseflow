# frozen_string_literal: true

class StraightVacateAndReadjudicationTask < DecidedMotionToVacateTask
  def self.label
    COPY::STRAIGHT_VACATE_AND_READJUDICATION_TASK_LABEL
  end

  def org
    JudgeTeam.for_judge(assigned_by)
  end
end
