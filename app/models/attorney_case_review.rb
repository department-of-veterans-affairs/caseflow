class AttorneyCaseReview < ApplicationRecord
  include CaseReviewConcern

  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"
  belongs_to :task

  validates :attorney, :document_type, :task_id, :reviewing_judge, :document_id, :work_product, presence: true
  validates :overtime, inclusion: { in: [true, false] }
  validates :work_product, inclusion: { in: QueueMapper::WORK_PRODUCTS.values }
  validates :note, length: { maximum: 350 }

  enum document_type: {
    omo_request: Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
    draft_decision: Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"]
  }

  def update_in_vacols!
    MetricsService.record("VACOLS: reassign_case_to_judge #{task_id}",
                                service: :vacols,
                                name: document_type) do
      reassign_case_to_judge_in_vacols!
      update_issue_dispositions_in_vacols! if draft_decision?
    end
  end

  def update_issue_dispositions
    issues.each do |issue|
      decision_issue = appeal.decision_issues.find_by(id: issue["id"])
      decision_issue.update(disposition: issue["disposition"]) if decision_issue
    end
  end

  private

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
        modifying_user: modifying_user,
        reassigned_to_judge_date: VacolsHelper.local_date_with_utc_timezone
      }
    )
  end

  def modifying_user
    attorney.vacols_uniq_id
  end

  class << self
    attr_writer :repository

    def complete(params)
      ActiveRecord::Base.multi_transaction do
        record = create(params)
        return record unless record.valid?
        record.legacy? ? record.update_in_vacols! : record.update_issue_dispositions
        record
      end
    end

    def repository
      return QueueRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= QueueRepository
    end
  end
end
