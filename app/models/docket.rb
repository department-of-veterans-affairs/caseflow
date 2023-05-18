# frozen_string_literal: true

class Docket
  include ActiveModel::Model
  include DistributionConcern

  def docket_type
    fail Caseflow::Error::MustImplementInSubclass
  end

  # :reek:LongParameterList
  def appeals(priority: nil, genpop: nil, ready: nil, judge: nil)
    fail "'ready for distribution' value cannot be false" if ready == false

    scope = docket_appeals.active

    if ready
      scope = scope.ready_for_distribution
      scope = adjust_for_genpop(scope, genpop, judge) if judge.present? && !use_by_docket_date?
    end

    return scoped_for_priority(scope) if priority == true

    scope = scope.nonpriority if priority == false

    scope.order("appeals.receipt_date")
  end

  def count(priority: nil, ready: nil)
    # The underlying scopes here all use `group_by` statements, so calling
    # `count` on `appeals` will return a hash. To get the number of appeals, we
    # can pluck the ids and ask for the size of the resulting array.
    # See the docs for ActiveRecord::Calculations
    appeals(priority: priority, ready: ready).ids.size
  end

  def genpop_priority_count
    # By default all cases are considered genpop. This can be overridden for specific dockets
    # For evidence submission and direct review docket, all appeals are genpop;
    # Don't need to specify anything more than "ready" and "priority".
    # This is overridden in hearing request docket.
    count(priority: true, ready: true)
  end

  def weight
    count
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    appeals(priority: true, ready: true).limit(num).map(&:ready_for_distribution_at)
  end

  def age_of_n_oldest_priority_appeals_available_to_judge(_judge, num)
    appeals(priority: true, ready: true).limit(num).map(&:receipt_date)
  end

  # this method needs to have the same name as the method in legacy_docket.rb for by_docket_date_distribution,
  # but the judge that is passed in isn't relevant here
  def age_of_n_oldest_nonpriority_appeals_available_to_judge(_judge, num)
    appeals(priority: false, ready: true).limit(num).map(&:receipt_date)
  end

  def age_of_oldest_priority_appeal
    if use_by_docket_date?
      @age_of_oldest_priority_appeal ||= appeals(priority: true, ready: true).limit(1).first&.receipt_date
    else
      @age_of_oldest_priority_appeal ||= appeals(priority: true, ready: true).limit(1).first&.ready_for_distribution_at
    end
  end

  def oldest_priority_appeal_days_waiting
    return 0 if age_of_oldest_priority_appeal.nil?

    (Time.zone.now.to_date - age_of_oldest_priority_appeal.to_date).to_i
  end

  def ready_priority_appeal_ids
    appeals(priority: true, ready: true).pluck(:uuid)
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Lint/UnusedMethodArgument
  # :reek:FeatureEnvy
  def distribute_appeals(distribution, priority: false, genpop: nil, limit: 1, style: "push")
    appeals = appeals(priority: priority, ready: true, genpop: genpop, judge: distribution.judge).limit(limit)
    tasks = assign_judge_tasks_for_appeals(appeals, distribution.judge)
    tasks.map do |task|
      next if task.nil?

      # If a distributed case already exists for this appeal, alter the existing distributed case's case id.
      # This is modeled after the allow! method in the redistributed_case model
      distributed_case = DistributedCase.find_by(case_id: task.appeal.uuid)
      if distributed_case && task.appeal.can_redistribute_appeal?
        distributed_case.flag_redistribution(task)
        distributed_case.rename_for_redistribution!
        new_dist_case = distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                                               docket: docket_type,
                                                               priority: priority,
                                                               ready_at: task.appeal.ready_for_distribution_at,
                                                               task: task)
        # In a race condition for distributions, two JudgeAssignTasks will be created; this cancels the first one
        cancel_previous_judge_assign_task(task.appeal, distribution.judge.id)
        # Returns the new DistributedCase as expected by calling methods; case in elsif is implicitly returned
        new_dist_case
      elsif !distributed_case
        distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                               docket: docket_type,
                                               priority: priority,
                                               ready_at: task.appeal.ready_for_distribution_at,
                                               task: task)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Lint/UnusedMethodArgument

  def self.nonpriority_decisions_per_year
    Appeal.extending(Scopes).nonpriority
      .joins(:decision_documents)
      .where("decision_date > ?", 1.year.ago)
      .pluck(:id).size
  end

  private

  # :reek:ControlParameter
  def adjust_for_genpop(scope, genpop, judge)
    (genpop == "not_genpop") ? scope.non_genpop_for_judge(judge) : scope.genpop
  end

  def scoped_for_priority(scope)
    if use_by_docket_date?
      scope.priority.order("appeals.receipt_date")
    else
      scope.priority.ordered_by_distribution_ready_date
    end
  end

  def docket_appeals
    Appeal.where(docket_type: docket_type).extending(Scopes)
  end

  def use_by_docket_date?
    FeatureToggle.enabled?(:acd_distribute_by_docket_date, user: RequestStore.store[:current_user])
  end

  module Scopes
    include DistributionScopes

    def priority
      include_aod_motions
        .where("advance_on_docket_motions.created_at > appeals.established_at")
        .where("advance_on_docket_motions.granted = ?", true)
        .or(include_aod_motions.where("people.date_of_birth <= ?", 75.years.ago))
        .or(include_aod_motions.where("appeals.stream_type = ?", Constants.AMA_STREAM_TYPES.court_remand))
        .group("appeals.id")
    end

    def nonpriority
      include_aod_motions
        .where("people.date_of_birth > ? or people.date_of_birth is null", 75.years.ago)
        .where.not("appeals.stream_type = ?", Constants.AMA_STREAM_TYPES.court_remand)
        .group("appeals.id")
        .having("count(case when advance_on_docket_motions.granted "\
          "\n and advance_on_docket_motions.created_at > appeals.established_at then 1 end) = ?", 0)
    end

    def include_aod_motions
      joins(:claimants)
        .joins("LEFT OUTER JOIN people on people.participant_id = claimants.participant_id")
        .joins("LEFT OUTER JOIN advance_on_docket_motions on advance_on_docket_motions.person_id = people.id")
    end

    def ready_for_distribution
      joins(:tasks)
        .group("appeals.id")
        .having("count(case when tasks.type = ? and tasks.status = ? then 1 end) >= ?",
                DistributionTask.name, Constants.TASK_STATUSES.assigned, 1)
    end

    def genpop
      joins(with_assigned_distribution_task_sql)
        .where(
          "appeals.stream_type != ? OR distribution_task.assigned_at <= ?",
          Constants.AMA_STREAM_TYPES.court_remand,
          Constants.DISTRIBUTION.cavc_affinity_days.days.ago
        )
    end

    def with_original_appeal_and_judge_task
      joins("LEFT JOIN cavc_remands ON cavc_remands.remand_appeal_id = appeals.id")
        .joins("LEFT JOIN appeals AS original_cavc_appeal ON original_cavc_appeal.id = cavc_remands.source_appeal_id")
        .joins(
          "LEFT JOIN tasks AS original_judge_task ON original_judge_task.appeal_id = original_cavc_appeal.id
           AND original_judge_task.type = 'JudgeDecisionReviewTask'
           AND original_judge_task.status = 'completed'"
        )
    end

    # Within the first 21 days, the appeal should be distributed only to the issuing judge.
    def non_genpop_for_judge(judge)
      joins(with_assigned_distribution_task_sql)
        .with_original_appeal_and_judge_task
        .where("distribution_task.assigned_at > ?", Constants.DISTRIBUTION.cavc_affinity_days.days.ago)
        .where(original_judge_task: { assigned_to_id: judge.id })
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
