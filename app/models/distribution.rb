class Distribution < ApplicationRecord
  include ActiveModel::Serializers::JSON
  include LegacyCaseDistribution

  has_many :distributed_cases
  belongs_to :judge, class_name: "User"

  validates :judge, presence: true
  validate :validate_user_is_judge, on: :create
  validate :validate_judge_has_no_unassigned_cases, on: :create
  validate :validate_judge_has_no_pending_distributions, on: :create

  enum status: { pending: "pending", started: "started", error: "error", completed: "completed" }

  before_create :mark_as_pending
  after_commit :enqueue_distribution_job, on: :create

  CASES_PER_ATTORNEY = 5
  ALTERNATIVE_BATCH_SIZE = 10

  def distribute!
    return unless %w[pending error].include? status

    if status == "error"
      return unless valid?(context: :create)
    end

    update(status: "started")

    legacy_distribution

    update(status: "completed", completed_at: Time.zone.now, statistics: legacy_statistics)
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

  def validate_judge_has_no_unassigned_cases
    errors.add(:judge, :unassigned_cases) unless judge_has_no_unassigned_cases
  end

  def validate_judge_has_no_pending_distributions
    errors.add(:judge, :pending_distribution) if self.class.pending_for_judge(judge).any?
  end

  def judge_has_no_unassigned_cases
    return false if assigned_tasks.any?

    legacy_tasks = QueueRepository.tasks_for_user(judge.css_id)
    legacy_tasks.none? { |task| task.assigned_to_attorney_date.nil? }
  end

  def assigned_tasks
    pending_statuses = [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    judge.tasks.select do |t|
      assigned_legacy_task = t.is_a?(JudgeLegacyTask) && t.action == "assign"
      (assigned_legacy_task || t.is_a?(JudgeAssignTask)) && pending_statuses.include?(t.status)
    end
  end

  def batch_size
    Constants::AttorneyJudgeTeams::JUDGES[Rails.current_env][judge.css_id]
      .try(:[], :attorneys)
      .try(:count)
      .try(:*, CASES_PER_ATTORNEY) || ALTERNATIVE_BATCH_SIZE
  end

  def total_batch_size
    attorney_count = Constants::AttorneyJudgeTeams::JUDGES[Rails.current_env].inject(0) do |sum, judge|
      sum + judge[1][:attorneys].count
    end

    attorney_count * CASES_PER_ATTORNEY
  end

  def distributed_cases_count
    (status == "completed") ? distributed_cases.count : 0
  end
end
