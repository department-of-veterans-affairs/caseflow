class Distribution < ApplicationRecord
  include LegacyCaseDistribution

  has_many :appeals
  has_many :legacy_appeals
  belongs_to :judge, class_name: "User"

  validates :judge, presence: true
  validate :user_is_judge
  validate :judge_has_no_unassigned_cases

  CASES_PER_ATTORNEY = 5
  ALTERNATIVE_BATCH_SIZE = 10

  def request!
    save!
    legacy_case_distribution
  end

  private

  def user_is_judge
    judge.judge_in_vacols?
  end

  def judge_has_no_unassigned_cases
    return false if JudgeTask.where(assigned_to: judge, action: "assign").any?

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
      sum + judge[:attorneys].count
    end

    attorney_count * CASES_PER_ATTORNEY
  end
end
