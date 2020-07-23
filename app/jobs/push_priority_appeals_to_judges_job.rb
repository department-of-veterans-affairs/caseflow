# frozen_string_literal: true

# Job that pushes priority cases to a judge rather than waiting for them to request cases. This will distribute cases
# to all judges whose teams that have `accepts_priority_pushed_cases` enabled. The first step distributes all priority
# cases tied to a judge without limit. The second step distributes remaining general population cases (cases not tied to
# an active judge) while attempting to even out the number of priority cases all judges have received over one month
class PushPriorityAppealsToJudgesJob < CaseflowJob
  include AutomaticCaseDistribution

  def perform
    @tied_distributions = distribute_non_genpop_priority_appeals
    @genpop_distributions = distribute_genpop_priority_appeals
    send_job_report
  end

  def send_job_report
    slack_service.send_notification(slack_report.join("\n"), self.class.name, "#appeals-job-alerts")
    datadog_report_runtime(metric_group_name: "priority_appeal_push_job")
  end

  def slack_report
    report = []
    report << "#{@tied_distributions.map { |stats| stats['batch_size'] }.sum} cases tied to judges distributed"
    report << "#{@genpop_distributions.map { |stats| stats['batch_size'] }.sum} genpop cases distributed"

    appeals_not_distributed = docket_coordinator.dockets.map do |docket_type, docket|
      [docket_type, docket.ready_priority_appeal_ids]
    end.to_h

    if appeals_not_distributed.values.flatten.any?
      report << "[WARN]"
      report << "Legacy appeals not distributed: `LegacyAppeal.where(vacols_id: #{appeals_not_distributed[:legacy]})`"
      ama_appeals_not_distributed = appeals_not_distributed.values.drop(1).flatten
      report << "AMA appeals not distributed: `Appeal.where(uuid: #{ama_appeals_not_distributed})`"
      docket_coordinator.dockets.each do |docket_type, docket|
        report << "Age of oldest #{docket_type} case: #{docket.oldest_priority_appeal_days_waiting} days"
      end
      report << COPY::PRIORITY_PUSH_WARNING_MESSAGE
    end

    report
  end

  # Distribute all priority cases tied to a judge without limit
  def distribute_non_genpop_priority_appeals
    eligible_judges.map do |judge|
      Distribution.create!(judge: judge, priority_push: true).tap(&:distribute!)
    end
  end

  # Distribute remaining general population cases while attempting to even out the number of priority cases all judges
  # have received over one month
  def distribute_genpop_priority_appeals
    eligible_judge_target_distributions_with_leftovers.map do |judge, target|
      Distribution.create!(judge: judge, priority_push: true).tap { |distribution| distribution.distribute!(target) }
    end
  end

  # Give any leftover cases to judges with the lowest distribution targets. Remove judges with 0 cases to be distributed
  # as these are the final counts to distribute remaining ready priority cases
  def eligible_judge_target_distributions_with_leftovers
    leftover_cases = leftover_cases_count
    eligible_judge_target_distributions.sort_by(&:last).map do |judge, target|
      if leftover_cases > 0
        leftover_cases -= 1
        target += 1
      end
      (target > 0) ? [judge, target] : nil
    end.compact.to_h
  end

  # Because we cannot distribute fractional cases, there can be cases leftover after taking the priority target
  # into account. This number will always be less than the number of judges that need distribution because division
  def leftover_cases_count
    ready_priority_appeals_count - eligible_judge_target_distributions.values.sum
  end

  # Calculate the number of cases a judge should receive based on the priority target. Don't toss out judges with 0 as
  # they could receive some of the leftover cases (if any)
  def eligible_judge_target_distributions
    eligible_judge_priority_distributions_this_month.map do |judge, distributions_this_month|
      target = priority_target - distributions_this_month
      (target >= 0) ? [judge, target] : nil
    end.compact.to_h
  end

  # Calculates a target that will distribute all ready appeals so the remaining counts for each judge will produce
  # even case counts over a full month (or as close as we can get to it)
  def priority_target
    @priority_target ||= begin
      distribution_counts = eligible_judge_priority_distributions_this_month.values
      target = (distribution_counts.sum + ready_priority_appeals_count) / distribution_counts.count

      while distribution_counts.any? { |distribution_count| distribution_count > target }
        distribution_counts = distribution_counts.reject { |distribution_count| distribution_count > target }
        target = (distribution_counts.sum + ready_priority_appeals_count) / distribution_counts.count
      end

      target
    end
  end

  def docket_coordinator
    @docket_coordinator ||= DocketCoordinator.new
  end

  def ready_priority_appeals_count
    @ready_priority_appeals_count ||= docket_coordinator.priority_count
  end

  # Number of priority distributions every eligible judge has received in the last month
  def eligible_judge_priority_distributions_this_month
    eligible_judges.map { |judge| [judge, judge_priority_distributions_this_month[judge.id] || 0] }.to_h
  end

  def eligible_judges
    @eligible_judges ||= JudgeTeam.pushed_priority_cases_allowed.map(&:judge)
  end

  # Produces a hash of judge_id and the number of cases distributed to them in the last month
  def judge_priority_distributions_this_month
    @judge_priority_distributions_this_month ||= priority_distributions_this_month
      .pluck(:judge_id, :statistics)
      .group_by(&:first)
      .map { |judge_id, arr| [judge_id, arr.flat_map(&:last).map { |stats| stats["batch_size"] }.sum] }.to_h
  end

  def priority_distributions_this_month
    Distribution.priority_push.completed.where(completed_at: 30.days.ago..Time.zone.now)
  end
end
