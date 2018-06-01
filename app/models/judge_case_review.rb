class JudgeCaseReview < ApplicationRecord
  belongs_to :judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  # task ID is vacols_id concatenated with the date assigned
  validates :task_id, format: { with: /\A[0-9A-Z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }

  enum title: {
    omo_request: "omo_request",
    draft_decision: "draft_decision"
  }

  def sign_decision_or_create_omo!
    judge.access_to_task?(vacols_id)

    JudgeCaseReview.repository.sign_decision_or_create_omo!(
      vacols_id: vacols_id,
      created_in_vacols_date: created_in_vacols_date,
      type: title,
      decass_attrs: {
        complexity: complexity,
        quality: quality,
        deficiencies: factors_not_considered + areas_for_improvement,
        comment: comment,
        modifying_user: judge.vacols_uniq_id
      }
    )
  end

  private

  def vacols_id
    task_id.split("-", 2).first
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date
  end

  class << self
    attr_writer :repository

    def create(params)
      ActiveRecord::Base.multi_transaction do
        record = super
        if record.valid?
          MetricsService.record("VACOLS: judge_case_review #{record.task_id}",
                                service: :vacols,
                                name: record.title) do
            record.sign_decision_or_create_omo!
          end
        end
        record
      end
    end

    def repository
      return QueueRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= QueueRepository
    end
  end
end