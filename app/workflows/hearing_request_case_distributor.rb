# frozen_string_literal: true

class HearingRequestCaseDistributor
  include DistributionConcern

  def initialize(appeals:, genpop:, distribution:, priority:)
    @appeals = appeals
    @genpop = genpop
    @distribution = distribution
    @priority = priority
  end

  def call
    # The DistributedCases model validates genpop and genpop_query for a hearing or legacy case. These methods
    # will create one array for the appeals and one for their genpop values with matching indexes
    appeals_for_tasks = appeals_to_distribute.flatten.select { |obj| obj.is_a?(Appeal) }
    genpop_values = appeals_to_distribute.flatten.reject { |obj| obj.is_a?(Appeal) }

    # Creates JudgeAssignTasks for the appeals, then zip the genpop_values into the array for creating
    # the DistributedCases
    tasks = assign_judge_tasks_for_appeals(appeals_for_tasks, @distribution.judge).zip(genpop_values)

    tasks.map do |task, genpop_value|
      next if task.nil?

      # If a distributed case already exists for this appeal, alter the existing distributed case's case id.
      # This is modeled after the allow! method in the redistributed_case model
      distributed_case = DistributedCase.find_by(case_id: task.appeal.uuid)
      if distributed_case && task.appeal.can_redistribute_appeal?
        distributed_case.flag_redistribution(task)
        distributed_case.rename_for_redistribution!
        new_dist_case = create_distribution_case_for_task(task, genpop_value)

        # In a race condition for distributions, two JudgeAssignTasks will be created; this cancels the first one
        cancel_previous_judge_assign_task(task.appeal, @distribution.judge.id)
        # Returns the new DistributedCase as expected by calling methods; case in elsif is implicitly returned
        new_dist_case
      elsif !distributed_case
        create_distribution_case_for_task(task, genpop_value)
      end
    end
  end

  private

  attr_reader :appeals, :genpop, :distribution, :priority

  def appeals_to_distribute
    not_genpop_appeals.map { |appeal| [appeal, false] }.concat(only_genpop_appeals.map { |appeal| [appeal, true] })
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
