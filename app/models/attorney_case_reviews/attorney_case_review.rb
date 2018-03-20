class AttorneyCaseReview < ActiveRecord::Base
  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  validates :attorney, :type, :task_id, :reviewing_judge, :document_id, :work_product, presence: true
  validates :overtime, inclusion: { in: [true, false] }

  attr_accessor :issues

  # task ID is vacols_id concatenated with the date assigned
  validates :task_id, format: { with: /\A[0-9]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }

  EXCEPTIONS = [QueueRepository::QueueError,
                IssueRepository::IssueError,
                ActiveRecord::RecordInvalid].freeze

  def appeal
    @appeal ||= Appeal.find_or_create_by(vacols_id: vacols_id)
  end

  def reassign_case_to_judge_in_vacols!
    AttorneyCaseReview.repository.reassign_case_to_judge(
      attorney_css_id: attorney.css_id,
      vacols_id: vacols_id,
      date_assigned: date_assigned,
      judge_css_id: reviewing_judge.css_id,
      decass_attrs: {
        work_product: work_product,
        document_id: document_id,
        overtime: overtime,
        note: note
      }
    )
  end

  def update_issue_dispositions!
    (issues || []).each do |issue_attrs|
      Issue.update_in_vacols!(
        css_id: attorney.css_id,
        vacols_id: vacols_id,
        vacols_sequence_id: issue_attrs[:vacols_sequence_id],
        issue_attrs: {
          disposition: issue_attrs[:disposition],
          disposition_date: VacolsHelper.local_date_with_utc_timezone,
          remand_reasons: issue_attrs[:remand_reasons]
        }
      )
    end
  end

  private

  def vacols_id
    task_id.split("-", 2).first
  end

  def date_assigned
    task_id.split("-", 2).second.to_date
  end

  class << self
    attr_writer :repository

    def complete!(params)
      transaction do
        begin
          # Save to the Caseflow DB first to ensure required fields are present
          record = create!(params)
          record.reassign_case_to_judge_in_vacols!
          record.update_issue_dispositions! if record.type == "DraftDecision"
        # :nocov:
        rescue *EXCEPTIONS => e
          Raven.capture_exception(e)
          Rails.logger.warn(e)
          raise ActiveRecord::Rollback
        end
        # :nocov:
        record
      end
    end

    def repository
      @repository ||= QueueRepository
    end
  end
end
