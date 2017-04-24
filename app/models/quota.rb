class Quota
  include ActiveModel::Model

  DEFAULT_ASSIGNEE_PROJECTION = 1

  attr_accessor :date, :task_klass

  class CarryOverError < StandardError; end

  def recalculate_assignee_count!
    update_assignee_count!(assignee_count)
  end

  def update_assignee_count!(projection)
    @loaded_assignee_count = nil

    Rails.cache.write(redis_key, [active_assignees, projection.to_i].max, expires_in: nil)
  end

  def per_assignee
    (todays_tasks.count / assignee_count.to_f).ceil
  end

  def assignee_count
    set_carry_over_assignee_projection! unless loaded_assignee_count

    loaded_assignee_count
  end

  def persisted?
    !!loaded_assignee_count
  end

  class << self
    def for(date:, task_klass:)
      new(date: date, task_klass: task_klass)
    end
  end

  private

  def set_carry_over_assignee_projection!
    update_assignee_count!(carry_over_assignee_projection)
  end

  def carry_over_assignee_projection
    most_recent_quota.try(:assignee_count) || DEFAULT_ASSIGNEE_PROJECTION
  end

  def active_assignees
    @active_assignees ||= tasks_completed_today.map(&:user).uniq.count
  end

  def todays_tasks
    tasks_completed_today + tasks_to_complete_today
  end

  def tasks_completed_today
    @tasks_completed_today ||= task_klass.completed_today
  end

  def tasks_to_complete_today
    @tasks_to_complete_today ||= task_klass.to_complete
  end

  def most_recent_quota
    @most_recent_quota ||= most_recent_quotas.find(&:persisted?)
  end

  # Cap the search to the last month to avoid an infinite loop
  def most_recent_quotas
    (1...31).lazy.map { |days| Quota.for(date: date - days.days, task_klass: task_klass) }
  end

  def loaded_assignee_count
    @loaded_assignee_count = Rails.cache.read(redis_key).try(:to_i)
  end

  def redis_key
    "employee_count_#{task_klass}_#{date}"
  end
end
