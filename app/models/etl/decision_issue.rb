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

      if original.ama_decision_documents.any?
        appeal = original.ama_appeal
        docs = original.ama_decision_documents
        fail "what to do with multiple dec docs? #{docs.first.id}" if docs.count > 1

        doc = docs.first
        atty_tasks = appeal.tasks.of_type(:AttorneyTask)
        judge_tasks = appeal.tasks.of_type(:JudgeDecisionReviewTask)
        # binding.pry unless atty_tasks == original.attorney_tasks
        # binding.pry unless judge_tasks == original.judge_review_tasks
        binding.pry unless atty_tasks == original.tasks.where(type: :AttorneyTask)
        binding.pry unless judge_tasks == original.tasks.where(type: :JudgeDecisionReviewTask)

        atty_tasks = original.tasks.where(type: :AttorneyTask)
        judge_tasks = original.tasks.where(type: :JudgeDecisionReviewTask)
        # judge_tasks = original.judge_review_tasks2
# binding.pry
        pp [doc.citation_number, appeal.stream_docket_number, doc.decision_date,
          atty_tasks.map{|t| [t.assigned_to.id, t.assigned_to.css_id]},
          judge_tasks.map{|t| [t.assigned_to.id, t.assigned_to.css_id]},
          original.disposition, original.benefit_type, original.description, original.diagnostic_code]
        # binding.pry
      end

      target
    end
  end
end
