# frozen_string_literal: true

class PushPriorityAppealsToJudges < CaseflowJob
  include AmaCaseDistribution

  delegate :dockets, to: :docket_coordinator

  def perform
    distribute_non_genpop_priority_appeals
    distribute_genpop_priority_appeals
  end

  def distribute_non_genpop_priority_appeals
    elligable_judges.each do |judge|
      Distribution.create!(judge: judge, priority_push: true).distribute!
    end
  end

  def distribute_genpop_priority_appeals
    elligable_judges.each do |judge|
      target = priority_target - (monthly_judge_distributions[judge.id] || 0)
      Distribution.create!(judge: judge, priority_push: true).distribute!(target) if target > 0
    end
  end

  def docket_coordinator
    @docket_coordinator ||= DocketCoordinator.new
  end

  def number_of_ready_priority_appeals
    docket_coordinator.priority_count
  end

  def priority_target
    (total_distributions_this_month + number_of_ready_priority_appeals) / elligable_judges.count
  end

  # TODO: update with scope for judge teams available_for_priority_case_distribution?
  def elligable_judges
    @elligable_judges ||= JudgeTeam.map(&:judge)
  end

  # Produces a hash of judge_id and the number of cases distributed to them in the last month
  def monthly_judge_priority_distributions
    priority_distributions_this_month
      .pluck(:judge_id, :statistics)
      .group_by(&:first)
      .map { |judge_id, arr| [judge_id, arr.flat_map(&:last).map { |stats| stats["batch_size"] }.reduce(:+)] }.to_h
  end

  def total_priority_distributions_this_month
    @total_priority_distributions_this_month ||=
      priority_distributions_this_month.pluck(:statistics).map { |stats| stats["batch_size"] }.reduce(:+)
  end

  def priority_distributions_this_month
    @priority_distributions_this_month ||=
      Distribution.priority_push.completed.where(completed_at: 30.days.ago..Time.zone.now)
  end
end
