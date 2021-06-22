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

  # By default all cases are considered genpop. This can be overridden for specific dockets
  def genpop_priority_count
    count(priority: true, ready: true)
  end

  def weight
    count
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    appeals(priority: true, ready: true).limit(num).map(&:ready_for_distribution_at)
  end

  def age_of_oldest_priority_appeal
    @age_of_oldest_priority_appeal ||= appeals(priority: true, ready: true).limit(1).first&.ready_for_distribution_at
  end

  def oldest_priority_appeal_days_waiting
    return 0 if age_of_oldest_priority_appeal.nil?

    (Time.zone.now.to_date - age_of_oldest_priority_appeal.to_date).to_i
  end

  def ready_priority_appeal_ids
    appeals(priority: true, ready: true).pluck(:uuid)
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
    Appeal.joins(:claimants)
      .joins("left join unrecognized_appellants on claimants.id = unrecognized_appellants.claimant_id")
      .where(docket_type: docket_type)
      .where("unrecognized_appellants.id is null")
      .extending(Scopes)
  end

  def assign_judge_tasks_for_appeals(appeals, judge)
    appeals.map do |appeal|
      Rails.logger.info("Assigning judge task for appeal #{appeal.id}")
      task = JudgeAssignTaskCreator.new(appeal: appeal, judge: judge).call
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")

      Rails.logger.info("Closing distribution task for appeal #{appeal.id}")
      appeal.tasks.of_type(:DistributionTask).update(status: :completed)
      Rails.logger.info("Closing distribution task with task id #{task.id} to #{task.assigned_to.css_id}")

      task
    end
  end

  module Scopes
    def priority
      include_aod_motions
        .where("advance_on_docket_motions.created_at > appeals.established_at")
        .where("advance_on_docket_motions.granted = ?", true)
        .or(include_aod_motions.where("people.date_of_birth <= ?", 75.years.ago))
        .or(include_aod_motions.where("appeals.stream_type = ?", Constants.AMA_STREAM_TYPES.court_remand))
        .group("appeals.id")
    end

    # rubocop:disable Metrics/LineLength
    def nonpriority
      include_aod_motions
        .where("people.date_of_birth > ?", 75.years.ago)
        .where.not("appeals.stream_type = ?", Constants.AMA_STREAM_TYPES.court_remand)
        .group("appeals.id")
        .having("count(case when advance_on_docket_motions.granted and advance_on_docket_motions.created_at > appeals.established_at then 1 end) = ?", 0)
    end
    # rubocop:enable Metrics/LineLength

    def include_aod_motions
      joins(claimants: :person)
        .joins("LEFT OUTER JOIN advance_on_docket_motions on advance_on_docket_motions.person_id = people.id")
    end

    def ready_for_distribution
      joins(:tasks)
        .group("appeals.id")
        .having("count(case when tasks.type = ? and tasks.status = ? then 1 end) >= ?",
                DistributionTask.name, Constants.TASK_STATUSES.assigned, 1)
    end

    def ordered_by_distribution_ready_date
      joins(:tasks)
        .group("appeals.id")
        .order(
          Arel.sql("max(case when tasks.type = 'DistributionTask' then tasks.assigned_at end)")
        )
    end

    def non_ihp
      joins(:tasks)
        .group("appeals.id")
        .having("count(case when tasks.type = ? then 1 end) = ?",
                InformalHearingPresentationTask.name, 0)
    end
  end
end
