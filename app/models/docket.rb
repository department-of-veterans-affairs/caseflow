class Docket
  include ActiveModel::Model

  def docket_type
    fail Caseflow::Error::MustImplementInSubclass
  end

  def appeals(priority: nil, ready: nil)
    fail "'ready for distribution' value cannot be false" if ready == false

    scope = docket_appeals
    scope = scope.merge(Appeal.ready_for_distribution) if ready == true
    scope = scope.merge(Appeal.all_priority) if priority == true
    scope = scope.merge(Appeal.all_nonpriority) if priority == false

    if priority == true
      scope.merge(Appeal.ordered_by_distribution_ready_date)
    else
      scope.order("receipt_date")
    end
  end

  def count(priority: nil, ready: nil)
    # The underlying scopes here all use `group_by` statements,
    # so the result of `count` will be a hash of key value pairs
    # e.g. {{[65, 65]=>2, [66, 66]=>2, [67, 67]=>2}
    # We want a # returned here, so we count the number of key value pairs.
    appeals(priority: priority, ready: ready).count.length
  end

  def weight
    count
  end

  def age_of_n_oldest_priority_appeals(num)
    appeals(priority: true, ready: true).limit(num).map(&:ready_for_distribution_at)
  end

  # CMGTODO: unique index on distributed_cases.case_id to prevent distributing the same appeal twice
  # CMGTODO: update DistributedCase validation and add judge_task association
  # CMGTODO: should priority be false, or nil by default?
  # CMGTODO: should genpop & genpop_query be passed to this method as well
  def distribute_appeals(distribution, priority: false, limit: 1)
    Distribution.transaction do
      appeals = appeals(priority: priority, ready: true).limit(limit)

      tasks = assign_judge_tasks_for_appeals(appeals, distribution.judge)

      genpop_query = case priority
                     when false
                       "only_genpop"
                     when true
                       "not_genpop"
                     else
                       "any"
                     end

      tasks.map do |task|
        distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                               docket: docket_type,
                                               genpop_query: genpop_query,
                                               priority: priority,
                                               genpop: false,
                                               ready_at: task.appeal.ready_for_distribution_at)
      end
    end
  end

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

      task
    end
  end
end
