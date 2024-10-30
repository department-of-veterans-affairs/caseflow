# frozen_string_literal: true

class Docket
  include ActiveModel::Model
  include DistributionConcern
  include DistributionScopes

  PRIORITY = "priority"
  NON_PRIORITY = "non_priority"

  def docket_type
    fail Caseflow::Error::MustImplementInSubclass
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # :reek:LongParameterList
  def appeals(priority: nil, genpop: nil, ready: nil, judge: nil, not_affinity: nil)
    fail "'ready for distribution' value cannot be false" if ready == false

    scope = docket_appeals

    # The `ready_for_distribution` scope will functionally add a filter for active appeals, and adding it here first
    # will cause that scope to always return zero appeals.
    scope = scope.active unless ready

    if ready
      scope = scope.ready_for_distribution

      # adjust for non_genpop for distributing non_genpop appeals during the push priority job only
      if genpop == "not_genpop" && judge.present?
        scope = only_non_genpop_appeals_for_push_job(scope, judge)
      else
        scope = adjust_for_affinity(scope, not_affinity, judge)
      end
    end

    return scoped_for_priority(scope) if priority == true

    scope = scope.nonpriority if priority == false

    scope.order("appeals.receipt_date")
  end

  def ready_priority_nonpriority_appeals(priority: false, ready: true, judge: nil, genpop: nil, not_affinity: nil)
    priority_status = priority ? PRIORITY : NON_PRIORITY
    appeals = appeals(priority: priority, ready: ready, genpop: genpop, judge: judge, not_affinity: not_affinity)
    lever_item = "disable_ama_#{priority_status}_#{docket_type.downcase}"
    docket_type_lever = CaseDistributionLever.find_by_item(lever_item)
    docket_type_lever_value = docket_type_lever ? CaseDistributionLever.public_send(lever_item) : nil

    if docket_type_lever_value == "true"
      appeals.none
    elsif priority_status == NON_PRIORITY &&
          start_distribution_prior_to_goal&.is_toggle_active && calculate_days_for_time_goal_with_prior_to_goal > 0
      appeals.where("appeals.receipt_date <= ?", calculate_days_for_time_goal_with_prior_to_goal.days.ago)
    else
      appeals
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def count(priority: nil, ready: nil)
    # The underlying scopes here all use `group_by` statements, so calling
    # `count` on `appeals` will return a hash. To get the number of appeals, we
    # can pluck the ids and ask for the size of the resulting array.
    # See the docs for ActiveRecord::Calculations
    appeals(priority: priority, ready: ready).ids.size
  end

  # currently this is used for reporting needs
  def ready_to_distribute_appeals
    docket_appeals.ready_for_distribution
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
    ready_priority_nonpriority_appeals(
      priority: true,
      ready: true,
      genpop: true
    ).limit(num).map(&:ready_for_distribution_at)
  end

  def age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    ready_priority_nonpriority_appeals(priority: true, ready: true, judge: judge).limit(num).map(&:receipt_date)
  end

  def age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    ready_priority_nonpriority_appeals(priority: false, ready: true, judge: judge).limit(num).map(&:receipt_date)
  end

  def age_of_oldest_priority_appeal
    @age_of_oldest_priority_appeal ||=
      if use_by_docket_date?
        ready_priority_nonpriority_appeals(priority: true, ready: true, not_affinity: true).limit(1).first&.receipt_date
      else
        ready_priority_nonpriority_appeals(priority: true, ready: true, not_affinity: true)
          .limit(1).first&.ready_for_distribution_at
      end
  end

  def oldest_priority_appeal_days_waiting
    return 0 if age_of_oldest_priority_appeal.nil?

    (Time.zone.now.to_date - age_of_oldest_priority_appeal.to_date).to_i
  end

  def ready_priority_appeal_ids
    appeals(priority: true, ready: true).pluck(:uuid)
  end

  def tied_to_vljs(judge_ids)
    docket_appeals.ready_for_distribution
      .most_recent_hearings
      .tied_to_judges(judge_ids)
  end

  # rubocop:disable Metrics/MethodLength, Lint/UnusedMethodArgument, Metrics/PerceivedComplexity
  # :reek:FeatureEnvy
  def distribute_appeals(distribution, priority: false, genpop: nil, limit: 1, style: "push")
    if sct_distribution_enabled?
      query_args = { priority: priority, ready: true, genpop: genpop, judge: distribution.judge }
      appeals, sct_appeals = create_sct_appeals(query_args, limit)
    else
      appeals = ready_priority_nonpriority_appeals(
        priority: priority,
        ready: true,
        genpop: genpop,
        judge: distribution.judge
      ).limit(limit)
      sct_appeals = []
    end

    tasks = assign_judge_tasks_for_appeals(appeals, distribution.judge)
    sct_tasks = assign_sct_tasks_for_appeals(sct_appeals)
    tasks_array = tasks + sct_tasks
    tasks_array.map do |task|
      next if task.nil?

      # If a distributed case already exists for this appeal, alter the existing distributed case's case id.
      # This is modeled after the allow! method in the redistributed_case model
      distributed_case = DistributedCase.find_by(case_id: task.appeal.uuid)
      if distributed_case && task.appeal.can_redistribute_appeal?
        distributed_case.flag_redistribution(task)
        distributed_case.rename_for_redistribution!
        new_dist_case = create_distribution_case_for_task(distribution, task, priority)
        # In a race condition for distributions, two JudgeAssignTasks will be created; this cancels the first one
        cancel_previous_judge_assign_task(task.appeal, distribution.judge.id)
        # Returns the new DistributedCase as expected by calling methods; case in elsif is implicitly returned
        new_dist_case
      elsif !distributed_case
        create_distribution_case_for_task(distribution, task, priority)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Lint/UnusedMethodArgument, Metrics/PerceivedComplexity

  def self.nonpriority_decisions_per_year
    Appeal.extending(DistributionScopes).nonpriority
      .joins(:decision_documents)
      .where("decision_date > ?", 1.year.ago)
      .pluck(:id).size
  end

  # used for distribution_stats
  # :reek:ControlParameter
  # :reek:FeatureEnvy
  def affinity_date_count(in_window, priority)
    scope = docket_appeals.ready_for_distribution

    scope = if in_window
              scope.non_genpop_by_affinity_start_date
            else
              scope.genpop_by_affinity_start_date
            end

    return scoped_for_priority(scope).ids.size if priority

    scope.nonpriority.ids.size
  end

  def calculate_days_for_time_goal_with_prior_to_goal
    return 0 unless docket_time_goal > 0

    docket_time_goal - Integer(start_distribution_prior_to_goal.value)
  end

  def docket_time_goal
    @docket_time_goal ||= begin
      does_lever_exist = CaseDistributionLever.exists?(item: "ama_#{docket_type}_docket_time_goals")
      does_lever_exist ? CaseDistributionLever.public_send("ama_#{docket_type}_docket_time_goals") : 0
    end
  end

  def start_distribution_prior_to_goal
    @start_distribution_prior_to_goal ||=
      CaseDistributionLever.find_by(item: "ama_#{docket_type}_start_distribution_prior_to_goals")
  end

  private

  # :reek:ControlParameter
  def only_non_genpop_appeals_for_push_job(scope, judge)
    scope.non_genpop_with_case_distribution_lever(judge)
  end

  def adjust_for_affinity(scope, not_affinity, judge = nil)
    if judge.present?
      scope.genpop_with_case_distribution_lever.or(scope.non_genpop_with_case_distribution_lever(judge))
    elsif not_affinity
      scope
    else
      scope.genpop_with_case_distribution_lever
    end
  end

  def scoped_for_priority(scope)
    if use_by_docket_date?
      scope.priority.order("appeals.receipt_date")
    else
      scope.priority.ordered_by_distribution_ready_date
    end
  end

  def docket_appeals
    Appeal.where(docket_type: docket_type).extending(DistributionScopes)
  end

  def use_by_docket_date?
    FeatureToggle.enabled?(:acd_distribute_by_docket_date, user: RequestStore.store[:current_user])
  end

  def sct_distribution_enabled?
    FeatureToggle.enabled?(:specialty_case_team_distribution, user: RequestStore.store[:current_user])
  end

  # :reek:FeatureEnvy
  def create_distribution_case_for_task(distribution, task, priority)
    distribution.distributed_cases.create!(case_id: task.appeal.uuid,
                                           docket: docket_type,
                                           priority: priority,
                                           ready_at: task.appeal.ready_for_distribution_at,
                                           task: task,
                                           sct_appeal: task.is_a?(SpecialtyCaseTeamAssignTask))
  end
end
