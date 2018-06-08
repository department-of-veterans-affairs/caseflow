class AttorneyCaseReview < ApplicationRecord
  include LegacyTaskConcern

  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  validates :attorney, :document_type, :task_id, :reviewing_judge, :document_id, :work_product, presence: true
  validates :overtime, inclusion: { in: [true, false] }
  validates :work_product, inclusion: { in: QueueMapper::WORK_PRODUCTS.values }

  enum document_type: {
    omo_request: "omo_request",
    draft_decision: "draft_decision"
  }

  def reassign_case_to_judge_in_vacols!
    attorney.access_to_task?(vacols_id)

    AttorneyCaseReview.repository.reassign_case_to_judge!(
      vacols_id: vacols_id,
      created_in_vacols_date: created_in_vacols_date,
      judge_vacols_user_id: reviewing_judge.vacols_uniq_id,
      decass_attrs: {
        work_product: work_product,
        document_id: document_id,
        overtime: overtime,
        note: note,
        modifying_user: attorney.vacols_uniq_id,
        reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone
      }
    )
  end

  class << self
    attr_writer :repository

    def complete(params)
      ActiveRecord::Base.multi_transaction do
        record = create(params)
        if record.valid?
          MetricsService.record("VACOLS: reassign_case_to_judge #{record.task_id}",
                                service: :vacols,
                                name: record.document_type) do
            record.reassign_case_to_judge_in_vacols!
            record.update_issue_dispositions! if record.draft_decision?
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
