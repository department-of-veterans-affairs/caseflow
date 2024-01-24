# frozen_string_literal: true

module DistributionConcern
  extend ActiveSupport::Concern

  private

  def assign_judge_tasks_for_appeals(appeals, judge)
    appeals.map do |appeal|
      # If an appeal does not have an open DistributionTask, then it has already been distributed by automatic
      # case distribution and a new JudgeAssignTask should not be created. This should only occur if two users
      # request a distribution simultaneously.
      # puts appeal.tasks.of_type(:DistributionTask).first.inspect
      next nil unless appeal.tasks.open.of_type(:DistributionTask).any?

      distribution_task_assignee_id = appeal.tasks.of_type(:DistributionTask).first.assigned_to_id
      Rails.logger.info("Calling JudgeAssignTaskCreator for appeal #{appeal.id} with judge #{judge.css_id}")
      JudgeAssignTaskCreator.new(appeal: appeal,
                                 judge: judge,
                                 assigned_by_id: distribution_task_assignee_id).call
    end
  end

  def assign_sct_tasks_for_appeals(appeals)
    appeals.map do |appeal|
      puts appeal.tasks.of_type(:DistributionTask).first.status.inspect
      next nil unless appeal.tasks.open.of_type(:DistributionTask).any?

      puts "creating sct task for appeal id: #{appeal.id}"
      distribution_task_assignee_id = appeal.tasks.of_type(:DistributionTask).first.assigned_to_id
      Rails.logger.info("Calling SCTAssignTaskCreator for appeal #{appeal.id}")
      SCTAssignTaskCreator.new(appeal: appeal,
                               assigned_by_id: distribution_task_assignee_id).call
    end
  end

  def cancel_previous_judge_assign_task(appeal, judge_id)
    appeal.tasks.of_type(:JudgeAssignTask).where.not(assigned_to_id: judge_id).update(status: :cancelled)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create_sct_appeals(appeals_args, limit)
    # sct_predicates = [
    #   proc { |appeal| appeal.request_issues.any? { |issue| issue.benefit_type == "vha" } }
    # ]

    appeals = appeals(appeals_args)
      .limit(limit)
      .includes(:request_issues)

    # TODO: Maybe expand this out so work with any possible benefit types or some selection criterion.
    # Something like SCT_PREDICATES
    sct_appeals = if FeatureToggle.enabled?(:specialty_case_team_distribution)
                    sct_appeals = appeals.select do |appeal|
                      appeal.request_issues.find do |issue|
                        issue.benefit_type == "vha"
                      end
                    end
                    appeals -= sct_appeals
                    sct_appeals
                  else
                    []
                  end

    puts "Feature toggle on: #{FeatureToggle.enabled?(:specialty_case_team_distribution)}"
    puts "limit: #{limit}"
    puts "appeals_args: #{appeals_args}"
    puts "appeals_count: #{appeals.count}"
    puts "sct_appeals: #{sct_appeals.count}"

    if sct_appeals.any?
      loop do
        inner_appeals = appeals(appeals_args)
          .limit(limit - appeals.count)
          .includes(:request_issues)
          .where("appeals.id NOT IN (?)", appeals.pluck(:id) + sct_appeals.pluck(:id))

        break unless inner_appeals.exists?

        inner_sct_appeals = inner_appeals.select do |appeal|
          appeal.request_issues.find do |issue|
            issue.benefit_type == "vha"
          end
        end

        inner_appeals -= inner_sct_appeals
        appeals += inner_appeals
        sct_appeals += inner_sct_appeals

        break if appeals.count >= limit
      end
    end

    [appeals, sct_appeals]
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
