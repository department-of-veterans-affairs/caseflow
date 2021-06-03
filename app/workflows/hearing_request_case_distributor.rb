# frozen_string_literal: true

class HearingRequestCaseDistributor
  def initialize(appeals:, distribution:, priority:)
    @appeals = appeals
    @distribution = distribution
    @priority = priority
  end

  def call
    appeals.map do |appeal|
      Distribution.transaction do
        rename_any_existing_distributed_case(appeal)
        task = create_judge_assign_task_for_appeal(appeal)
        create_distribution_case_for_task(task)
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

  attr_reader :appeals, :distribution, :priority

  def create_judge_assign_task_for_appeal(appeal)
    JudgeAssignTaskCreator.new(appeal: appeal, judge: distribution.judge).call
  end

  def create_distribution_case_for_task(task)
    distribution.distributed_cases.create!(
      case_id: task.appeal.uuid,
      docket: Constants.AMA_DOCKETS.hearing,
      priority: priority,
      ready_at: task.appeal.ready_for_distribution_at,
      task: task,
      genpop: :true,
      genpop_query: :true
    )
  end
end
