# frozen_string_literal: true

class HearingRequestCaseDistributor
  def initialize(appeals:, genpop:, distribution:, priority:)
    @appeals = appeals
    @genpop = genpop
    @distribution = distribution
    @priority = priority
  end

  def call
    appeals_to_distribute.map do |appeal, genpop_value|
      Distribution.transaction do
        rename_any_existing_distributed_case(appeal)
        task = create_judge_assign_task_for_appeal(appeal)
        create_distribution_case_for_task(task, genpop_value)
      end
    end
  end

  def rename_any_existing_distributed_case(appeal)
    existing_case = DistributedCase.find_by(case_id: appeal.uuid)
    if existing_case
      Raven.capture_message("Redistributing appeal #{appeal.uuid} to #{distribution.judge.css_id}")
      existing_case.rename_for_redistribution!
    end
  end

  private

  attr_reader :appeals, :genpop, :distribution, :priority

  def appeals_to_distribute
    not_genpop_appeals.map { |appeal| [appeal, false] }.concat(only_genpop_appeals.map { |appeal| [appeal, true] })
  end

  def create_judge_assign_task_for_appeal(appeal)
    JudgeAssignTaskCreator.new(appeal: appeal, judge: distribution.judge).call
  end

  def create_distribution_case_for_task(task, genpop_value)
    distribution.distributed_cases.create!(
      case_id: task.appeal.uuid,
      docket: Constants.AMA_DOCKETS.hearing,
      priority: priority,
      ready_at: task.appeal.ready_for_distribution_at,
      task: task,
      genpop: genpop_value,
      genpop_query: genpop
    )
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
