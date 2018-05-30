class AttorneyCaseReview < ApplicationRecord
  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  validates :attorney, :title, :task_id, :reviewing_judge, :document_id, :work_product, presence: true
  validates :overtime, inclusion: { in: [true, false] }
  validates :work_product, inclusion: { in: QueueMapper::WORK_PRODUCTS.values }

  enum title: {
    omo_request: "omo_request",
    draft_decision: "draft_decision"
  }

  attr_accessor :issues

  # task ID is vacols_id concatenated with the date assigned
  validates :task_id, format: { with: /\A[0-9]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }

  def appeal
    @appeal ||= LegacyAppeal.find_or_create_by(vacols_id: vacols_id)
  end

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

  def update_issue_dispositions!
    (issues || []).each do |issue_attrs|
      Issue.update_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: issue_attrs[:vacols_sequence_id],
        issue_attrs: {
          vacols_user_id: attorney.vacols_uniq_id,
          disposition: issue_attrs[:disposition],
          disposition_date: VacolsHelper.local_date_with_utc_timezone,
          readjudication: issue_attrs[:readjudication],
          remand_reasons: issue_attrs[:remand_reasons]
        }
      )
    end
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
          MetricsService.record("VACOLS: reassign_case_to_judge #{record.task_id}",
                                service: :vacols,
                                name: record.title) do
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
