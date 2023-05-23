# frozen_string_literal: true

class Distribution < CaseflowRecord
  include ActiveModel::Serializers::JSON
  if FeatureToggle.enabled?(:acd_distribute_by_docket_date, user: RequestStore.store[:current_user])
    include ByDocketDateDistribution
  else
    include AutomaticCaseDistribution
  end

  has_many :distributed_cases
  belongs_to :judge, class_name: "User"

  validates :judge, presence: true
  validate :validate_user_is_judge, on: :create
  validate :validate_number_of_unassigned_cases, on: :create, unless: :priority_push?
  validate :validate_days_waiting_of_unassigned_cases, on: :create, unless: :priority_push?
  validate :validate_judge_has_no_pending_distributions, on: :create

  enum status: { pending: "pending", started: "started", error: "error", completed: "completed" }

  before_create :mark_as_pending

  scope :priority_pushed, -> { where(priority_push: true) }

  class << self
    def pending_for_judge(judge)
      where(status: %w[pending started], judge: judge)
    end
  end

  def distribute!(limit = nil)
    return unless %w[pending error].include? status

    update!(status: :started, started_at: Time.zone.now)

    # this might take awhile due to VACOLS, so set our timeout to 3 minutes (in milliseconds).
    transaction_time_out = 3 * 60 * 1000

    multi_transaction do
      ActiveRecord::Base.connection.execute "SET LOCAL statement_timeout = #{transaction_time_out}"

      priority_push? ? priority_push_distribution(limit) : requested_distribution

      update!(status: "completed", completed_at: Time.zone.now, statistics: ama_statistics)
    end
  rescue StandardError => error
    # DO NOT use update! because we want to avoid validations and saving any cached associations.
    # Prevent prod database from getting Stacktraces as this is debugging information
    if Rails.deploy_env?(:prod)
      update_columns(status: "error", errored_at: Time.zone.now)
    else
      update_columns(status: "error", errored_at: Time.zone.now, statistics: error_statistics(error))
    end
    raise error
  end

  def distributed_cases_count
    (status == "completed") ? distributed_cases.count : 0
  end

  def distributed_batch_size
    statistics&.fetch("batch_size", 0) || 0
  end

  private

  def mark_as_pending
    self.status = "pending"
  end

  def validate_user_is_judge
    errors.add(:judge, :not_judge) unless judge.judge_in_vacols?
  end

  def validate_number_of_unassigned_cases
    errors.add(:judge, :too_many_unassigned_cases) unless judge_has_eight_or_fewer_unassigned_cases
  end

  def validate_days_waiting_of_unassigned_cases
    errors.add(:judge, :unassigned_cases_waiting_too_long) if judge_cases_waiting_longer_than_thirty_days
  end

  def validate_judge_has_no_pending_distributions
    if self.class.pending_for_judge(judge).where(priority_push: priority_push).exists?
      errors.add(:judge, :pending_distribution)
    end
  end

  def judge_tasks
    @judge_tasks ||= assigned_tasks
  end

  def judge_legacy_tasks
    return [] if FeatureToggle.enabled?(:acd_disable_legacy_distributions, user: RequestStore.store[:current_user])

    legacy_tasks = QueueRepository.tasks_for_user(judge.css_id)

    @judge_legacy_tasks ||= legacy_tasks.select { |task| task.assigned_to_attorney_date.nil? }
  end

  def judge_has_eight_or_fewer_unassigned_cases
    return false if judge_tasks.length > Constants.DISTRIBUTION.request_more_cases_minimum

    judge_tasks.length + judge_legacy_tasks.length <= Constants.DISTRIBUTION.request_more_cases_minimum
  end

  def judge_cases_waiting_longer_than_thirty_days
    return true if judge_tasks.any? { |task| longer_than_thirty_days_ago(task.assigned_at) }

    judge_legacy_tasks.any? { |task| longer_than_thirty_days_ago(task.assigned_to_location_date.try(:to_date)) }
  end

  def longer_than_thirty_days_ago(date)
    return false if date.nil?

    date.beginning_of_day < 30.days.ago.beginning_of_day
  end

  def assigned_tasks
    judge.tasks.select do |t|
      t.is_a?(JudgeAssignTask) && t.active?
    end
  end

  def batch_size
    team_batch_size = JudgeTeam.for_judge(judge)&.attorneys&.size

    return Constants.DISTRIBUTION.alternative_batch_size if team_batch_size.nil? || team_batch_size == 0

    team_batch_size * Constants.DISTRIBUTION.batch_size_per_attorney
  end

  def error_statistics(error)
    {
      error: error&.full_message
    }
  end
end
