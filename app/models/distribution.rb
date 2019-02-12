class Distribution < ApplicationRecord
  include ActiveModel::Serializers::JSON
  include LegacyCaseDistribution
  include AmaCaseDistribution

  has_many :distributed_cases
  belongs_to :judge, class_name: "User"

  validates :judge, presence: true
  validate :validate_user_is_judge, on: :create
  validate :validate_number_of_unassigned_cases, on: :create
  validate :validate_days_waiting_of_unassigned_cases, on: :create
  validate :validate_judge_has_no_pending_distributions, on: :create

  enum status: { pending: "pending", started: "started", error: "error", completed: "completed" }

  before_create :mark_as_pending
  after_commit :enqueue_distribution_job, on: :create

  CASES_PER_ATTORNEY = 3
  ALTERNATIVE_BATCH_SIZE = 5

  def distribute!
    return unless %w[pending error].include? status

    if status == "error"
      return unless valid?(context: :create)
    end

    update(status: "started")

    if FeatureToggle.enabled?(:ama_auto_case_distribution, user: RequestStore.store[:current_user])
      ama_distribution
      update(status: "completed", completed_at: Time.zone.now, statistics: ama_statistics)
    else
      legacy_distribution
      update(status: "completed", completed_at: Time.zone.now, statistics: legacy_statistics)
    end
  rescue StandardError => e
    update(status: "error")
    raise e
  end

  def self.pending_for_judge(judge)
    where(status: %w[pending started], judge: judge)
  end

  private

  def attributes
    { 'id': nil, 'status': nil, 'created_at': nil, 'updated_at': nil, 'distributed_cases_count': nil }
  end

  def mark_as_pending
    self.status = "pending"
  end

  def enqueue_distribution_job
    if Rails.env.development? || Rails.env.test?
      StartDistributionJob.perform_now(self)
    else
      StartDistributionJob.perform_later(self, RequestStore[:current_user])
    end
  end

  def validate_user_is_judge
    errors.add(:judge, :not_judge) unless judge.judge_in_vacols?
  end

  def validate_number_of_unassigned_cases
    errors.add(:judge, :too_many_unassigned_cases) unless judge_has_eight_or_fewer_unassigned_cases
  end

  def validate_days_waiting_of_unassigned_cases
    errors.add(:judge, :unassigned_cases_waiting_too_long) if judge_cases_waiting_longer_than_two_weeks
  end

  def validate_judge_has_no_pending_distributions
    errors.add(:judge, :pending_distribution) if self.class.pending_for_judge(judge).any?
  end

  def judge_tasks
    @judge_tasks ||= assigned_tasks
  end

  def judge_legacy_tasks
    legacy_tasks = QueueRepository.tasks_for_user(judge.css_id)

    @judge_legacy_tasks ||= legacy_tasks.select { |task| task.assigned_to_attorney_date.nil? }
  end

  def judge_has_eight_or_fewer_unassigned_cases
    return false if judge_tasks.length > 8

    judge_tasks.length + judge_legacy_tasks.length <= 8
  end

  def judge_cases_waiting_longer_than_two_weeks
    return true if judge_tasks.any? { |task| longer_than_two_weeks_ago(task.assigned_at) }

    judge_legacy_tasks.any? { |task| longer_than_two_weeks_ago(task.assigned_to_location_date.try(:to_date)) }
  end

  def longer_than_two_weeks_ago(date)
    return false if date.nil?

    date.beginning_of_day < 14.days.ago.beginning_of_day
  end

  def assigned_tasks
    pending_statuses = [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    judge.tasks.select do |t|
      t.is_a?(JudgeAssignTask) && pending_statuses.include?(t.status)
    end
  end

  def batch_size
    JudgeTeam.for_judge(judge)
      .try(:non_admins)
      .try(:count)
      .try(:*, CASES_PER_ATTORNEY) || ALTERNATIVE_BATCH_SIZE
  end

  def total_batch_size
    JudgeTeam.all.map(&:non_admins).flatten.count * CASES_PER_ATTORNEY
  end

  def distributed_cases_count
    (status == "completed") ? distributed_cases.count : 0
  end
end
