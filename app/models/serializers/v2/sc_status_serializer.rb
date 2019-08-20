# frozen_string_literal: true

class V2::SCStatusSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :supplemental_claim
  set_id :review_status_id

  attribute :appeal_ids, &:linked_review_ids

  attribute :updated do
    Time.zone.now.in_time_zone("Eastern Time (US & Canada)").round.iso8601
  end

  attribute :incomplete_history do
    false
  end

  attribute :active, &:active?
  attribute :description

  attribute :location do
    "aoj"
  end

  attribute :aoj
  attribute :program_area, &:program
  attribute :status do |object|
    StatusSerializer.new(object).serializable_hash[:data][:attributes]
  end

  attribute :alerts
  attribute :issues do |object|
    issues_list = object.active? ? object.request_issues.active.all : object.fetch_all_decision_issues
    IssueSerializer.new(issues_list, is_collection: true).serializable_hash[:data].collect { |issue| issue[:attributes] }
  end

  attribute :events

  # Stubbed attributes
  attribute :evidence do
    []
  end
end
