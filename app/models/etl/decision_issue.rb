# frozen_string_literal: true

# copy of decision_issues

class ETL::DecisionIssue < ETL::Record
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes.reject { |key| %w[created_at updated_at deleted_at].include?(key) }
      target.issue_created_at = original.created_at
      target.issue_updated_at = original.updated_at
      target.issue_deleted_at = original.deleted_at

      appeal = original.ama_appeal
      atty_tasks = appeal.tasks.of_type(:AttorneyTask) if appeal
      judge_tasks = appeal.tasks.of_type(:JudgeDecisionReviewTask) if appeal
      if appeal
        target.docket_number = appeal.stream_docket_number
        # binding.pry unless atty_tasks == original.attorney_tasks
        # binding.pry unless judge_tasks == original.judge_review_tasks
        binding.pry unless atty_tasks == original.tasks.where(type: :AttorneyTask)
        binding.pry unless judge_tasks == original.tasks.where(type: :JudgeDecisionReviewTask)
      end

      atty_tasks = original.tasks.where(type: :AttorneyTask).where.not(status: :cancelled)
      fail "what to do with multiple atty_tasks? #{atty_tasks.pluck :id}" if atty_tasks.count > 1

      atty_task = atty_tasks.first

      judge_tasks = original.tasks.where(type: :JudgeDecisionReviewTask).where.not(status: :cancelled)
      fail "what to do with multiple judge_tasks? #{judge_tasks.pluck :id}" if judge_tasks.count > 1

      judge_task = judge_tasks.first

      if judge_task
        target.judge_user_id = judge_task.assigned_to.id
        target.judge_css_id = judge_task.assigned_to.css_id
      end
      if atty_task
        target.attorney_user_id = atty_task.assigned_to.id
        target.attorney_css_id = atty_task.assigned_to.css_id
      end

      docs = original.ama_decision_documents
      fail "what to do with multiple dec docs? #{docs.pluck :id}" if docs.count > 1

      doc = docs.first
      if doc
        pp [doc.citation_number, appeal.stream_docket_number, doc.decision_date,
            atty_tasks.map { |t| [t.assigned_to.id, t.assigned_to.css_id] },
            judge_tasks.map { |t| [t.assigned_to.id, t.assigned_to.css_id] },
            original.disposition, original.benefit_type, original.description, original.diagnostic_code]
        # binding.pry

        target.decision_doc_id = doc.id
        target.doc_citation_number = doc.citation_number
        target.doc_decision_date = doc.decision_date
        end

      target
    end
  end
end
