# frozen_string_literal: true

class WorkQueue::DecisionReviewTaskSerializer
  include FastJsonapi::ObjectSerializer

  def self.decision_review(object)
    object.appeal
  end

  def self.claimant_with_name(object)
    decision_review(object).claimants.find { |claimant| claimant.name.present? }
  end

  def self.claimant_name(object)
    if decision_review(object).veteran_is_not_claimant
      # TODO: support multiple?
      object[:claimant_name] || claimant_with_name(object).try(:name) || "claimant"
    else
      veteran_name = object[:claimant_name] || decision_review(object).veteran_full_name
      veteran_name.presence ? veteran_name : "claimant"
    end
  end

  def self.claimant_relationship(object)
    return "self" unless decision_review(object).veteran_is_not_claimant

    claimant = claimant_with_name(object)
    return "Unknown" if claimant.nil?

    claimant.relationship.presence || claimant.class.name.delete_suffix("Claimant")
  end

  def self.request_issues(object)
    decision_review(object).request_issues
  end

  def self.power_of_attorney(object)
    decision_review(object).claimant&.power_of_attorney
  end

  def self.issue_count(object)
    object[:issue_count] || request_issues(object).active_or_ineligible.size
  end

  def self.veteran(object)
    decision_review(object).veteran
  end

  attribute :claimant do |object|
    {
      name: claimant_name(object),
      # Cheat using an sql alias from the decision_review_queue query page to avoid
      # serializing the relationship on the queue page since it isn't used in the table display
      relationship: object[:claimant_name] || claimant_relationship(object)
    }
  end

  attribute :appeal do |object|
    # If :issue_count is present then we're hitting this serializer from a Decision Review
    # queue table, and we do not need to gather request issues as they are not used there.
    skip_acquiring_request_issues = object[:issue_count]
    {
      id: decision_review(object).external_id,
      uuid: decision_review(object).uuid,
      isLegacyAppeal: false,
      issueCount: issue_count(object),
      activeRequestIssues: skip_acquiring_request_issues || request_issues(object).active.map(&:serialize),
      appellant_type: decision_review(object).claimant&.type
    }
  end

  attribute :power_of_attorney do |object|
    if power_of_attorney(object).nil?
      nil
    else
      {
        representative_type: power_of_attorney(object)&.representative_type,
        representative_name: power_of_attorney(object)&.representative_name,
        representative_address: power_of_attorney(object)&.representative_address,
        representative_email_address: power_of_attorney(object)&.representative_email_address
      }
    end
  end

  attribute :appellant_type do |object|
    decision_review(object).claimant&.type
  end

  attribute :issue_count do |object|
    issue_count(object)
  end

  attribute :issue_types do |object|
    object[:issue_types] || request_issues(object).active.pluck(:nonrating_issue_category).join(",")
  end

  attribute :tasks_url do |object|
    object.assigned_to.tasks_url
  end

  attribute :id
  attribute :created_at

  attribute :veteran_participant_id do |object|
    object[:veteran_participant_id] || veteran(object).participant_id
  end

  attribute :veteran_ssn do |object|
    object[:veteran_ssn] || veteran(object).ssn
  end

  attribute :assigned_on, &:assigned_at
  attribute :assigned_at

  attribute :closed_at
  attribute :started_at

  attribute :type do |object|
    decision_review(object).is_a?(Appeal) ? "Board Grant" : decision_review(object).class.review_title
  end

  attribute :business_line do |object|
    assignee = object.assigned_to

    assignee.is_a?(BusinessLine) ? assignee.url : nil
  end
end
