class Distribution < ApplicationRecord
  include LegacyCaseDistribution

  has_many :distributed_cases
  belongs_to :judge, class_name: "User"

  validates :judge, presence: true
  validate :validate_user_is_judge, on: :create
  validate :validate_judge_has_no_unassigned_cases, on: :create

  after_create :distribute

  CASES_PER_ATTORNEY = 5
  ALTERNATIVE_BATCH_SIZE = 10

  private

  def distribute
    if acting_judge
      legacy_acting_judge_distribution
    else
      legacy_distribution
    end

    update(statistics: legacy_statistics, completed_at: Time.zone.now)
  end

  def acting_judge
    judge.attorney_in_vacols?
  end

  def validate_user_is_judge
    errors.add(:judge, "must be a judge in VACOLS") unless judge.judge_in_vacols?
  end

  def validate_judge_has_no_unassigned_cases
    errors.add(:judge, "must have no unassigned cases") unless judge_has_no_unassigned_cases
  end

  def judge_has_no_unassigned_cases
    pending_statuses = [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    return false if JudgeTask.where(assigned_to: judge, action: "assign", status: pending_statuses).any?

    legacy_tasks = QueueRepository.tasks_for_user(judge.css_id)
    legacy_tasks.none? { |task| task.assigned_to_attorney_date.nil? }
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
end
