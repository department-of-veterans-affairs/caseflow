class TeamQuota < ActiveRecord::Base
  DEFAULT_USER_COUNT = 1

  class MismatchedTeamQuota < StandardError; end

  before_save :adjust_user_count

  # Only assigned quotas are saved
  has_many :assigned_quotas, class_name: "UserQuota"

  def user_quotas
    assigned_quotas + unassigned_quotas
  end

  def task_count_for(user_quota)
    fail MismatchedTeamQuota if user_quota.team_quota_id != id

    calculate_task_count_for(assigned_quotas.index(user_quota))
  end

  def task_klass
    task_type.is_a?(String) ? task_type.constantize : task_type
  end

  private

  def calculate_task_count_for(quota_index)
    task_count_per_user + (remainder_task_count > quota_index ? 1 : 0)
  end

  # To save excessive DB saves & reads, auto generate all unassigned quotas
  # instead of saving them to the DB
  def unassigned_quotas
    return [] if assigned_quotas.count >= user_count

    unassigned_quotas_index_range.map do |index|
      UserQuota.new(team_quota_id: id, task_count: calculate_task_count_for(index))
    end
  end

  def unassigned_quotas_index_range
    (assigned_quotas.count..(user_count - 1))
  end

  def task_count_per_user
    tasks.count / user_count
  end

  def remainder_task_count
    tasks.count % user_count
  end

  def tasks
    tasks_completed + tasks_to_complete
  end

  def tasks_completed
    @tasks_completed ||= task_klass.completed_on(date)
  end

  def tasks_to_complete
    @tasks_to_complete ||= (date == Time.zone.today) ? task_klass.to_complete : []
  end

  def adjust_user_count
    carry_over_user_count unless user_count

    self.user_count = [assigned_quotas.count, user_count].max
  end

  def carry_over_user_count
    self.user_count = most_recent_user_count || DEFAULT_USER_COUNT
  end

  def most_recent_user_count
    @most_recent_user_count ||= most_recent_user_counts.find(&:nonzero?)
  end

  # Cap the search to the last month to avoid an infinite loop
  def most_recent_user_counts
    self.class.where(task_type: task_type).order(:date).limit(31).lazy.map(&:user_count)
  end
end
