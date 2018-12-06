class Docket
  include ActiveModel::Model

  def docket_type
    fail Caseflow::Error::MustImplementInSubclass
  end

  def appeals(priority: nil, ready: nil)
    scope = docket_appeals
    scope = scope.merge(Appeal.where_priority(priority)) unless priority.nil?
    scope = scope.merge(Appeal.where_ready_for_distribution(ready)) unless ready.nil?
    scope.order("#{priority ? 'ready_for_distribution_at' : 'receipt_date'} ASC")
  end

  def count(priority: nil, ready: nil)
    appeals(priority, ready).count
  end

  def weight
    count
  end

  def age_of_n_oldest_priority_appeals(n)
    appeals(priority: true, ready: true).limit(n).pluck("ready_for_distribution_at")
  end

  # CMGTODO: unique index on distributed_cases.case_id to prevent distributing the same appeal twice
  # CMGTODO: update DistributedCase validation and add judge_task association
  def distribute_appeals(distribution, priority: false, limit: 1)
    transaction do
      appeals = appeals(priority: priority, ready: true).limit(limit)

      tasks = assign_judge_tasks_for_appeals(appeals, distribution.judge)

      tasks.map do |task|
        distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                               docket: docket_type,
                                               priority: priority,
                                               ready_at: task.appeal.ready_for_distribution_at,
                                               judge_task: task)
      end
    end
  end

  private

  # CMGTODO: only return active appeals
  def docket_appeals
    Appeal.where(docket_type: docket_type)
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
