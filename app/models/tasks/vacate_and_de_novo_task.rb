# frozen_string_literal: true

class VacateAndDeNovoTask < DecidedMotionToVacateTask
  def self.label
    COPY::VACATE_AND_DE_NOVO_TASK_LABEL
  end

  def org
    JudgeTeam.for_judge(assigned_by)
  end
end
