# frozen_string_literal: true

class WorkQueue::VeteranRecordRequestSerializer < WorkQueue::DecisionReviewTaskSerializer
  include FastJsonapi::ObjectSerializer

  def self.claimant_name(object)
    decision_review(object).claimant.try(:name)
  end

  def self.claimant_relationship(object)
    return "self" unless decision_review(object).veteran_is_not_claimant

    decision_review(object).claimant.try(:relationship)
  end

  attribute :appeal do |object|
    {
      id: decision_review(object).external_id,
      isLegacyAppeal: false,
      issueCount: issue_count(object)
    }
  end

  attribute :assigned_at
  attribute :type, &:label
end
