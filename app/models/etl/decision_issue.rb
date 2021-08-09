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
binding.pry
    # pp hash_result.map{|r| r["attorney_ids"].split(',').uniq.map{|id| user_cache(id).css_id}}
      target
    end
  end
end
