# frozen_string_literal: true

class HearingRequestCaseDistributor
  def initialize(appeals:, genpop:, distribution:, priority:)
    @appeals = appeals
    @genpop = genpop
    @distribution = distribution
    @priority = priority
  end

  def call
    Distribution.transaction do
      tasks = assign_judge_tasks_for_appeals

      tasks.map do |task, genpop_value|
        distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                               docket: "hearing",
                                               priority: priority,
                                               ready_at: task.appeal.ready_for_distribution_at,
                                               task: task,
                                               genpop: genpop_value,
                                               genpop_query: genpop)
      end
    end
  end

  private

  attr_reader :appeals, :genpop, :distribution, :priority

  def assign_judge_tasks_for_appeals
    assign_judge_tasks_for_not_genpop_appeals.concat(assign_judge_tasks_for_only_genpop_appeals)
  end

  def assign_judge_tasks_for_not_genpop_appeals
    CreateJudgeAssignTasksForAppeals.new(appeals: not_genpop_appeals, judge: distribution.judge).call.map do |task|
      [task, false]
    end
  end

  def assign_judge_tasks_for_only_genpop_appeals
    CreateJudgeAssignTasksForAppeals.new(appeals: only_genpop_appeals, judge: distribution.judge).call.map do |task|
      [task, true]
    end
  end

  def not_genpop_appeals
    return appeals if genpop == "not_genpop"

    return appeals[0] if genpop == "any"

    []
  end

  def only_genpop_appeals
    return appeals if genpop == "only_genpop"

    return appeals[1] if genpop == "any"

    []
  end
end
