# frozen_string_literal: true

module DistributionConcern
  extend ActiveSupport::Concern

  private

  # A list of tasks which are expected or allowed to be open at time of distribution
  ALLOWABLE_TASKS = [
    RootTask.name,
    DistributionTask.name,
    JudgeAssignTask.name,
    TrackVeteranTask.name,
    VeteranRecordRequest.name,
    *MailTask.subclasses.reject(&:blocking?).map(&:name)
  ].freeze

  def assign_judge_tasks_for_appeals(appeals, judge)
    appeals.map do |appeal|
      check_for_unexpected_tasks(appeal)

      # If an appeal does not have an open DistributionTask, then it has already been distributed by automatic
      # case distribution and a new JudgeAssignTask should not be created. This should only occur if two users
      # request a distribution simultaneously.
      next nil unless appeal.tasks.open.of_type(:DistributionTask).any? && appeal.active?

      distribution_task_assignee_id = appeal.tasks.of_type(:DistributionTask).first.assigned_to_id
      Rails.logger.info("Calling JudgeAssignTaskCreator for appeal #{appeal.id} with judge #{judge.css_id}")
      JudgeAssignTaskCreator.new(appeal: appeal,
                                 judge: judge,
                                 assigned_by_id: distribution_task_assignee_id).call
    end
  end

  # Check for tasks which are open that we would not expect to see at the time of distribution. Send a slack
  # message for notification of a potential bug in part of the application, but do not stop the distribution
  def check_for_unexpected_tasks(appeal)
    unless appeal.tasks.open.reject { |task| ALLOWABLE_TASKS.include?(task.class.name) }.empty? && appeal.active?
      send_slack_notification(appeal)
    end
  end

  def send_slack_notification(appeal)
    msg = "Appeal #{appeal.id}. Check its task tree for a potential bug or tasks which need to be manually remediated"
    title = "Appeal with unexpected open tasks during distribution"
    SlackService.new.send_notification(msg, title)
  end

  def assign_sct_tasks_for_appeals(appeals)
    appeals.map do |appeal|
      next nil unless appeal.tasks.open.of_type(:DistributionTask).any?

      distribution_task_assignee_id = appeal.tasks.of_type(:DistributionTask).first.assigned_to_id
      Rails.logger.info("Calling SpecialtyCaseTeamAssignTaskCreator for appeal #{appeal.id}")
      SpecialtyCaseTeamAssignTaskCreator.new(appeal: appeal,
                                             assigned_by_id: distribution_task_assignee_id).call
    end
  end

  def cancel_previous_judge_assign_task(appeal, judge_id)
    appeal.tasks.of_type(:JudgeAssignTask).where.not(assigned_to_id: judge_id).update(status: :cancelled)
  end

  # rubocop:disable Metrics/MethodLength
  # :reek:FeatureEnvy
  def create_sct_appeals(appeals_args, limit)
    appeals = ready_priority_nonpriority_appeals(appeals_args)
      .limit(limit)
      .includes(:request_issues)

    sct_appeals = if FeatureToggle.enabled?(:specialty_case_team_distribution, user: RequestStore.store[:current_user])
                    sct_appeals = appeals.select(&:sct_appeal?)
                    appeals -= sct_appeals
                    sct_appeals
                  else
                    []
                  end
0
    if sct_appeals.any? && limit.present?
      loop do
        inner_appeals = ready_priority_nonpriority_appeals(appeals_args)
          .limit(limit - appeals.count)
          .includes(:request_issues)
          .where("appeals.id NOT IN (?)", appeals.pluck(:id) + sct_appeals.pluck(:id))

        break unless inner_appeals.exists?

        inner_sct_appeals = inner_appeals.select(&:sct_appeal?)
        inner_appeals -= inner_sct_appeals
        appeals += inner_appeals
        sct_appeals += inner_sct_appeals

        break if appeals.count >= limit
      end
    end

    [appeals, sct_appeals]
  end
  # rubocop:enable Metrics/MethodLength
end
