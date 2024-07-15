# frozen_string_literal: true

class PushPriorityReport
  def initialize(genpop_distributions,
                 tied_distributions,
                 priority_target,
                 priority_distributions_this_month_for_eligible_judges)
    @report = []
    @genpop_distributions = genpop_distributions
    @tied_distributions = tied_distributions
    @priority_target = priority_target
    @priority_distributions_this_month_for_eligible_judges = priority_distributions_this_month_for_eligible_judges
  end

  def generate
    num_of_cases_distributed

    @report << "Priority Target: #{@priority_target}"

    appeals_not_distributed = docket_coordinator.age_of_oldest_by_docket_report(@report)
    num_of_appeals_not_distributed(appeals_not_distributed)
    docket_coordinator.num_of_appeals_not_distributed_by_affinity_date_report(@report)

    @report << ""
    @report << "*Debugging information*"

    excluded_judges_reporting

    @report << "Previous monthly distributions {judge_id=>count}: #{@priority_distributions_this_month_for_eligible_judges}" # rubocop:disable Layout/LineLength

    @report
  end

  private

  def docket_coordinator
    @docket_coordinator ||= DocketCoordinator.new
  end

  def use_by_docket_date?
    FeatureToggle.enabled?(:acd_distribute_by_docket_date, user: RequestStore.store[:current_user])
  end

  def num_of_cases_distributed
    if use_by_docket_date?
      total_cases = @genpop_distributions.map(&:distributed_cases_count).sum
      @report << "*Number of cases distributed*: " \
                "#{total_cases}"
    else
      tied_distributions_sum = @tied_distributions.map(&:distributed_cases_count).sum
      genpop_distributions_sum = @genpop_distributions.map(&:distributed_cases_count).sum
      @report << "*Number of cases tied to judges distributed*: " \
                "#{tied_distributions_sum}"
      @report << "*Number of general population cases distributed*: " \
                "#{genpop_distributions_sum}"
    end
  end

  def num_of_appeals_not_distributed(appeals_not_distributed)
    @report << ""
    @report << "*Total Number of appeals _not_ distributed*: #{appeals_not_distributed.values.flatten.count}"

    docket_coordinator.num_of_appeals_not_distributed_report(@report)

    @report << "*Number of Legacy Hearing Non Genpop appeals _not_ distributed*: #{legacy_not_genpop_count}"
  end

  def legacy_not_genpop_count
    docket_coordinator.dockets[:legacy].not_genpop_priority_count
  end

  def excluded_judges_reporting
    excluded_judges = JudgeTeam.judges_with_exclude_appeals_from_affinity.pluck(:css_id)
    @report << "*Excluded Judges*: #{excluded_judges}"
  end
end
