# frozen_string_literal: true

module IssuesFieldSerializer
  extend ActiveSupport::Concern

  class_methods do
    protected

    def issues(object)
      IssueSerializer.new(object.active_request_issues_or_decision_issues, is_collection: true)
        .serializable_hash[:data].collect { |issue| issue[:attributes] }
    end
  end
end
