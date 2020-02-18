# frozen_string_literal: true

class Docket
  include ActiveModel::Model

  def docket_type
    fail Caseflow::Error::MustImplementInSubclass
  end

  def appeals(priority: nil, ready: nil)
    fail "'ready for distribution' value cannot be false" if ready == false

    scope = docket_appeals.active
    scope = scope.ready_for_distribution if ready == true

    if priority == true
      scope = scope.priority
      return scope.ordered_by_distribution_ready_date
    end

    scope = scope.nonpriority if priority == false
    scope.order("receipt_date")
  end

  def count(priority: nil, ready: nil)
    # The underlying scopes here all use `group_by` statements, so calling
    # `count` on `appeals` will return a hash. To get the number of appeals, we
    # can pluck the ids and ask for the size of the resulting array.
    # See the docs for ActiveRecord::Calculations
    appeals(priority: priority, ready: ready).ids.size
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

  def self.nonpriority_decisions_per_year
    Appeal.extending(Scopes).nonpriority
      .joins(:decision_documents)
      .where("decision_date > ?", 1.year.ago)
      .pluck(:id).size
  end

  private

  def docket_appeals
    Appeal.where(docket_type: docket_type).extending(Scopes)
  end

  def assign_judge_tasks_for_appeals(appeals, judge)
    appeals.map do |appeal|
      Rails.logger.info("Assigning judge task for appeal #{appeal.id}")
      task = JudgeAssignTaskCreator.new(appeal: appeal, judge: judge).call
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")

      Rails.logger.info("Closing distribution task for appeal #{appeal.id}")
      appeal.tasks.where(type: DistributionTask.name).update(status: :completed)
      Rails.logger.info("Closing distribution task with task id #{task.id} to #{task.assigned_to.css_id}")

      task
    end
  end

  module Scopes
    def priority
      join_aod_motions
        .where("advance_on_docket_motions.created_at > appeals.established_at")
        .where("advance_on_docket_motions.granted = ?", true)
        .or(join_aod_motions
          .where("people.date_of_birth <= ?", 75.years.ago))
        .group("appeals.id")
    end

    # rubocop:disable Metrics/LineLength
    def nonpriority
      join_aod_motions
        .where("people.date_of_birth > ?", 75.years.ago)
        .group("appeals.id")
        .having("count(case when advance_on_docket_motions.granted and advance_on_docket_motions.created_at > appeals.established_at then 1 end) = ?", 0)
    end
    # rubocop:enable Metrics/LineLength

    def join_aod_motions
      joins(claimants: :person)
        .joins("LEFT OUTER JOIN advance_on_docket_motions on advance_on_docket_motions.person_id = people.id")
    end

    def ready_for_distribution
      joins(:tasks)
        .group("appeals.id")
        .having("count(case when tasks.type = ? and tasks.status = ? then 1 end) >= ?",
                DistributionTask.name, Constants.TASK_STATUSES.assigned, 1)
        .having("count(case when tasks.type in (?) and tasks.status not in (?) then 1 end) = ?",
                MailTask.blocking_subclasses, Task.closed_statuses, 0)
    end

    def ordered_by_distribution_ready_date
      joins(:tasks)
        .group("appeals.id")
        .order(Arel.sql("max(case when tasks.type = 'DistributionTask' then tasks.assigned_at end)"))
    end

    def non_ihp
      joins(:tasks)
        .group("appeals.id")
        .having("count(case when tasks.type = ? then 1 end) = ?",
                InformalHearingPresentationTask.name, 0)
    end
  end
end
