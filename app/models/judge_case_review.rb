# frozen_string_literal: true

class JudgeCaseReview < CaseflowRecord
  include CaseReviewConcern
  include IssueUpdater

  belongs_to :judge, class_name: "User"
  belongs_to :attorney, class_name: "User"
  belongs_to :task

  validates :task_id, :location, :judge, :attorney, presence: true
  validates :complexity, :quality, presence: true, if: :bva_dispatch?
  validates :comment, length: { maximum: Constants::VACOLS_COLUMN_MAX_LENGTHS["DECASS"]["DEBMCOM"] }

  after_create :select_case_for_legacy_quality_review

  scope :this_month, -> { where(created_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month) }

  enum location: {
    omo_office: "omo_office",
    bva_dispatch: "bva_dispatch",
    quality_review: "quality_review"
  }

  # This comment in the GH issue will explain the numbers
  # https://github.com/department-of-veterans-affairs/caseflow/issues/6407#issuecomment-409271892
  # LEGACY Limit and Probablity. See AMA at app/models/quality_review_case_selector.rb:5
  # As of Dec 2019, we want AMA and Legacy to use the same cap. The percentages may differ. The
  # goal is to get to the cap as steadily across the month as possible
  MONTHLY_LIMIT_OF_QUALITY_REVIEWS = 137
  QUALITY_REVIEW_SELECTION_PROBABILITY = 0.032

  def update_in_vacols!
    MetricsService.record("VACOLS: judge_case_review #{task_id}",
                          service: :vacols,
                          name: "judge_case_review_" + location) do
      sign_decision_or_create_omo!
      update_issue_dispositions_in_vacols! if bva_dispatch? || quality_review?
    end
  end

  def update_in_caseflow!
    task.update!(status: Constants.TASK_STATUSES.completed)
    update_issue_dispositions_in_caseflow!
  end

  private

  def sign_decision_or_create_omo!
    judge.fail_if_no_access_to_legacy_task!(vacols_id)

    JudgeCaseReview.repository.sign_decision_or_create_omo!(
      vacols_id: vacols_id,
      created_in_vacols_date: created_in_vacols_date,
      location: location.to_sym,
      decass_attrs: {
        complexity: complexity,
        quality: quality,
        one_touch_initiative: one_touch_initiative,
        deficiencies: factors_not_considered + areas_for_improvement,
        comment: comment,
        modifying_user: modifying_user,
        board_member_id: judge.vacols_attorney_id,
        completion_date: VacolsHelper.local_date_with_utc_timezone
      }
    )
  end

  def modifying_user
    judge.vacols_uniq_id
  end

  def select_case_for_legacy_quality_review
    return if !legacy? || self.class.reached_monthly_limit_in_quality_reviews?

    # We are using 25 sided die to randomly select a case for quality review
    # https://github.com/department-of-veterans-affairs/caseflow/issues/6407
    update(location: :quality_review) if bva_dispatch? && rand < QUALITY_REVIEW_SELECTION_PROBABILITY
  end

  class << self
    def complete(params)
      ActiveRecord::Base.multi_transaction do
        record = create(params)
        if record.valid?
          record.legacy? ? record.update_in_vacols! : record.update_in_caseflow!
          record.associate_with_appeal
        end
        record
      end
    end

    def reached_monthly_limit_in_quality_reviews?
      where(location: :quality_review).this_month.size >= MONTHLY_LIMIT_OF_QUALITY_REVIEWS
    end

    def repository
      QueueRepository
    end
  end
end
