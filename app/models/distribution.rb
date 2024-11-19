# frozen_string_literal: true

class Distribution < CaseflowRecord
  include ActiveModel::Serializers::JSON
  include ByDocketDateDistribution

  has_many :distributed_cases
  belongs_to :judge, class_name: "User"
  has_one :distribution_stats

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

      # update status and time before generating the statistics to reduce amount of time a user waits for cases
      update!(status: "completed", completed_at: Time.zone.now)
    end

    ama_stats = ama_statistics

    # need to store batch_size in the statistics column for use within the PushPriorityAppealsToJudgesJob
    update!(statistics: completed_statistics(ama_stats))

    record_distribution_stats(ama_stats)

    CaseDistributionLever.clear_distribution_lever_cache
  rescue StandardError => error
    process_error(error)
    title = "Distribution Failed"
    msg = "Distribution #{id} failed: #{error.message}}"
    SlackService.new.send_notification(msg, title)

    raise error
  end

  def distributed_cases_count
    (status == "completed") ? distributed_cases.count { |distributed_case| !distributed_case.sct_appeal } : 0
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
    legacy_tasks = QueueRepository.tasks_for_user(judge.css_id)

    @judge_legacy_tasks ||= legacy_tasks.select { |task| task.assigned_to_attorney_date.nil? }
  end

  def judge_has_eight_or_fewer_unassigned_cases
    return false if judge_tasks.length > CaseDistributionLever.request_more_cases_minimum

    judge_tasks.length + judge_legacy_tasks.length <= CaseDistributionLever.request_more_cases_minimum
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

  def team_size
    @team_size ||= JudgeTeam.for_judge(judge)&.attorneys&.size
  end

  def batch_size
    return CaseDistributionLever.alternative_batch_size if team_size.nil? || team_size == 0

    team_size * CaseDistributionLever.batch_size_per_attorney
  end

  def error_statistics(error)
    {
      statistics: {
        error: error&.full_message
      }
    }
  end

  def process_error(error)
    # DO NOT use update! because we want to avoid validations and saving any cached associations.
    # Prevent prod database from getting Stacktraces as this is debugging information
    if Rails.deploy_env?(:prod)
      update_columns(status: "error", errored_at: Time.zone.now)
      record_distribution_stats({})
    else
      update_columns(status: "error", errored_at: Time.zone.now, statistics: error_statistics(error))
      record_distribution_stats(error_statistics(error))
    end
  end

  # need to store batch_size in the statistics column for use within the PushPriorityAppealsToJudgesJob
  def completed_statistics(stats)
    {
      batch_size: stats[:statistics][:batch_size],
      info: "See related row in distribution_stats for additional stats"
    }
  end

  def record_distribution_stats(stats)
    create_distribution_stats!(stats.merge(levers: CaseDistributionLever.snapshot))
  end
end
