# frozen_string_literal: true

class WorkQueue::VeteranRecordRequestSerializer
  include FastJsonapi::ObjectSerializer

  def self.decision_review(object)
    object.appeal
  end

  def self.claimant_name(object)
    decision_review(object).claimant.try(:name)
  end

  def self.claimant_relationship(object)
    return "self" unless decision_review(object).veteran_is_not_claimant

    decision_review(object).claimant.try(:relationship)
  end

  attribute :claimant do |object|
    {
      name: claimant_name(object),
      relationship: claimant_relationship(object)
    }
  end

  attribute :appeal do |object|
    {
      id: decision_review(object).external_id,
      isLegacyAppeal: false,
      issueCount: decision_review(object).request_issues.active_or_ineligible.count
    }
  end

  attribute :tasks_url do |object|
    object.assigned_to.tasks_url
  end

  attribute :id
  attribute :created_at

  attribute :veteran_participant_id do |object|
    decision_review(object).veteran.participant_id
  end

  attribute :assigned_on, &:assigned_at
  attribute :closed_at
  attribute :started_at
  attribute :type, &:label
end
