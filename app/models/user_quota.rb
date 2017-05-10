class UserQuota < ActiveRecord::Base
  belongs_to :user
  belongs_to :team_quota

  attr_writer :task_count
  delegate :date, :task_klass, to: :team_quota

  after_create :update_team_quota

  def to_hash
    serializable_hash(methods: [:user_name, :task_count, :tasks_completed_count, :tasks_left_count])
  end

  def task_count
    @task_count ||= team_quota.task_count_for(self)
  end

  def tasks_completed_count
    @tasks_completed_count ||= user ? task_klass.completed_on(date).completed_by(user).count : 0
  end

  def tasks_left_count
    task_count - tasks_completed_count
  end

  def user_name
    user && user.full_name
  end

  private

  # Allow team quota to adjust values based on the new user quota
  def update_team_quota
    team_quota.save!
  end
end
