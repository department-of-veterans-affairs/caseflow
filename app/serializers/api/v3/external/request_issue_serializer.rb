# frozen_string_literal: true

class Api::V3::External::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer
  attributes :contention_removed_at, :contention_updated_at, :covid_timeliness_exempt, :decision_sync_attempted_at,
             :decision_sync_canceled_at, :decision_sync_error, :decision_sync_last_submitted_at,
             :decision_sync_processed_at, :decision_sync_submitted_at, :is_predocket_needed, :type, remove: true
  has_many :decision_issues, serializer: ::Api::V3::External::DecisionIssueSerializer
end
