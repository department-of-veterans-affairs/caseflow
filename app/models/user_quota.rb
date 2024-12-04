# frozen_string_literal: true

class UserQuota < CaseflowRecord
  belongs_to :user
  belongs_to :team_quota

  attr_writer :task_count

  delegate :date, :task_klass, to: :team_quota

  after_create :update_team_quota

  def to_hash
    serializable_hash(methods: [
                        :id,
                        :user_name,
                        :task_count,
                        :tasks_completed_count,
                        :tasks_completed_count_by_decision_type,
                        :tasks_left_count,
                        :locked?
                      ])
  end

  def task_count
    @task_count ||= locked_task_count || team_quota.task_count_for(self)
  end

  def tasks_completed_count
    @tasks_completed_count ||= user ? task_klass.completed_on(date).completed_by(user).count : 0
  end

  def tasks_left_count
    task_count - tasks_completed_count
  end

  def user_name
    user&.full_name
  end

  def locked?
    !!locked_task_count
  end

  def tasks_completed_count_by_decision_type
    completed_tasks_by_decision_type.each_with_object({}) do |decision, counts_by_decision|
      counts_by_decision[decision.first] = decision.second.count
    end
  end

  def completed_tasks_by_decision_type
    ClaimEstablishment
      .select(:decision_type)
      .where(
        task_id: Dispatch::Task.where(user_id: user_id).where("completed_at >= ?", date)
      ).group_by(&:decision_type)
  end

  # User quotas can either be
  # locked, which means the quota was manually set to the value in `locked_task_count`, or
  # unlocked, which means the quota is automatically distributed by the parent team quota
  def locked_task_count=(new_locked_task_count)
    self[:locked_task_count] = adjust_locked_task_count(new_locked_task_count)
  end

  private

  def adjust_locked_task_count(new_locked_task_count)
    return unless new_locked_task_count
    return new_locked_task_count unless team_quota

    # Guard from going above the maximum assignable tasks
    result = [max_locked_task_count, new_locked_task_count.to_i].min

    result = [min_locked_task_count, result].max if min_locked_task_count

    [0, result].max
  end

  def max_locked_task_count
    team_quota.tasks_to_assign + (locked_task_count || 0)
  end

  def min_locked_task_count
    # If there's only one or fewer users left to be calculated, the min is the same as the max
    (team_quota.unlocked_user_count <= 1 && team_quota.user_count <= 1) ? max_locked_task_count : nil
  end

  # Allow team quota to adjust values based on the new user quota
  def update_team_quota
    team_quota.save!
  end

  class << self
    def unlocked
      where(locked_task_count: nil)
    end

    def locked
      where.not(locked_task_count: nil)
    end
  end
end
