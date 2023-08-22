# frozen_string_literal: true

class AttorneyCaseReview < CaseflowRecord
  include CaseReviewConcern
  include HasAppealUpdatedSince
  include IssueUpdater
  include ::AmaAttorneyCaseReviewDocumentIdValidator

  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"
  belongs_to :task

  validates :attorney, :document_type, :task_id, :reviewing_judge, :document_id, :work_product, presence: true
  validates :untimely_evidence, inclusion: { in: [true, false] }
  validates :overtime, inclusion: { in: [true, false] }
  validates :work_product, inclusion: { in: QueueMapper::WORK_PRODUCTS.values }
  validates :note, length: { maximum: Constants::VACOLS_COLUMN_MAX_LENGTHS["DECASS"]["DEATCOM"] }

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

  def update_in_caseflow!
    task.update!(status: Constants.TASK_STATUSES.completed)

    if task.assigned_by_id != reviewing_judge_id
      task.parent.update(assigned_to_id: reviewing_judge_id)
    end
    task.parent.update(assigned_by_id: task.assigned_to_id)
    if note && !note.nil?
      labeled_note = note_label + note
      task.parent.append_instruction(labeled_note)
    end
    update_issue_dispositions_in_caseflow!
  end

  def update_in_vacols_and_caseflow!
    update_in_vacols!
    task.update!(status: Constants.TASK_STATUSES.completed)

    if task.assigned_by_id != reviewing_judge_id
      task.parent.update(assigned_to_id: reviewing_judge_id)
    end
    task.parent.update(assigned_by_id: task.assigned_to_id)
    if note && !note.nil?
      labeled_note = note_label + note
      task.parent.append_instruction(labeled_note)
    end
  end

  def written_by_name
    attorney.full_name
  end

  def note_label
    # Adding prefix and markup for better formatting of notes appended to judge task
    if task.is_a?(AttorneyRewriteTask)
      "**#{COPY::ATTORNEY_REWRITE_TASK_NOTES_PREFIX}**\n"
    elsif task.is_a?(AttorneyTask)
      "**#{COPY::ATTORNEY_TASK_NOTES_PREFIX}**\n"
    else
      ""
    end
  end

  private

  def reassign_case_to_judge_in_vacols!
    attorney.fail_if_no_access_to_legacy_task!(vacols_id)
    AttorneyCaseReview.repository.reassign_case_to_judge!(
      vacols_id: vacols_id,
      assigned_by: attorney,
      created_in_vacols_date: created_in_vacols_date,
      judge_vacols_user_id: reviewing_judge,
      decass_attrs: {
        work_product: work_product,
        document_id: document_id,
        overtime: overtime,
        note: note,
        modifying_user: modifying_user,
        reassigned_to_judge_date: VacolsHelper.local_time_with_utc_timezone
      }
    )
  end

  def modifying_user
    attorney.vacols_uniq_id
  end

  class << self
    def complete(params)
      ActiveRecord::Base.multi_transaction do
        record = create(params)
        if record.valid?
          if record.legacy? && record.task.type == "AttorneyTask"
            record.update_in_vacols_and_caseflow!
          else
            record.legacy? ? record.update_in_vacols! : record.update_in_caseflow!
          end
          record.associate_with_appeal
        end
        record
      end
    end

    def repository
      QueueRepository
    end
  end
end
