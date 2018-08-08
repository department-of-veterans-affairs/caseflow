class JudgeCaseReview < ApplicationRecord
  include LegacyTaskConcern

  belongs_to :judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  validates :task_id, :location, presence: true
  validates :complexity, :quality, presence: true, if: :bva_dispatch?

  after_create :select_case_for_quality_review

  scope :this_month, -> { where(created_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month) }

  enum location: {
    omo_office: "omo_office",
    bva_dispatch: "bva_dispatch",
    quality_review: "quality_review"
  }

  # This numbers need to be adjusted after a full rollout to judges
  MONTHLY_LIMIT_OF_QUAILITY_REVIEWS = 24
  QUALITY_REVIEW_SELECTION_PROBABILITY = 0.04

  def sign_decision_or_create_omo!
    judge.access_to_task?(vacols_id)

    JudgeCaseReview.repository.sign_decision_or_create_omo!(
      vacols_id: vacols_id,
      created_in_vacols_date: created_in_vacols_date,
      location: location.to_sym,
      decass_attrs: {
        complexity: complexity,
        quality: quality,
        deficiencies: factors_not_considered + areas_for_improvement,
        comment: comment,
        modifying_user: modifying_user,
        board_member_id: judge.vacols_attorney_id
      }
    )
  end

  def modifying_user
    judge.vacols_uniq_id
  end

  def select_case_for_quality_review
    return if self.class.reached_monthly_limit_in_quality_reviews?
    # We are using 25 sided die to randomly select a case for quality review
    # https://github.com/department-of-veterans-affairs/caseflow/issues/6407
    update(location: :quality_review) if bva_dispatch? && rand < QUALITY_REVIEW_SELECTION_PROBABILITY
  end

  class << self
    attr_writer :repository

    def complete(params)
      ActiveRecord::Base.multi_transaction do
        record = create(params)
        if record.valid?
          MetricsService.record("VACOLS: judge_case_review #{record.task_id}",
                                service: :vacols,
                                name: "judge_case_review_" + record.location) do
            record.sign_decision_or_create_omo!
            record.update_issue_dispositions! if record.bva_dispatch? || record.quality_review?
          end
        end
        record
      end
    end

    def reached_monthly_limit_in_quality_reviews?
      where(location: :quality_review).this_month.size >= MONTHLY_LIMIT_OF_QUAILITY_REVIEWS
    end

    def repository
      return QueueRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= QueueRepository
    end
  end
end
