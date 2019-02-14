class Docket
  include ActiveModel::Model

  def docket_type
    fail Caseflow::Error::MustImplementInSubclass
  end

  def appeals(priority: nil, ready: nil)
    fail "'ready for distribution' value cannot be false" if ready == false

    scope = docket_appeals
    scope = scope.merge(Appeal.ready_for_distribution) if ready == true

    if priority == true
      scope = scope.merge(Appeal.all_priority)
      return scope.merge(Appeal.ordered_by_distribution_ready_date)
    end

    scope = scope.merge(Appeal.all_nonpriority) if priority == false
    scope.order("receipt_date")
  end

  def count(priority: nil, ready: nil)
    # The underlying scopes here all use `group_by` statements,
    # so we count using a subquery finding the relevant ids.
    appeal_ids = appeals(priority: priority, ready: ready).select("appeals.id")
    Appeal.where(id: appeal_ids).count
  end

  def weight
    count
  end

  def age_of_n_oldest_priority_appeals(num)
    appeals(priority: true, ready: true).limit(num).map(&:ready_for_distribution_at)
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def distribute_appeals(distribution, priority: false, genpop: nil, limit: 1)
    Distribution.transaction do
      appeals = appeals(priority: priority, ready: true).limit(limit)

      tasks = assign_judge_tasks_for_appeals(appeals, distribution.judge)

      tasks.map do |task|
        distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                               docket: docket_type,
                                               priority: priority,
                                               ready_at: task.appeal.ready_for_distribution_at,
                                               task: task)
      end
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument

  private

  def docket_appeals
    Appeal.active.where(docket_type: docket_type)
  end

  def assign_judge_tasks_for_appeals(appeals, judge)
    appeals.map do |appeal|
      Rails.logger.info("Assigning judge task for appeal #{appeal.id}")
      task = JudgeTask.create!(appeal: appeal,
                               parent: appeal.root_task,
                               appeal_type: Appeal.name,
                               assigned_at: Time.zone.now,
                               assigned_to: judge,
                               action: "assign")
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")

      Rails.logger.info("Closing distribution task for appeal #{appeal.id}")
      appeal.tasks.where(type: DistributionTask.name).update(status: :completed)
      Rails.logger.info("Closing distribution task with task id #{task.id} to #{task.assigned_to.css_id}")

      task
    end
  end
end
