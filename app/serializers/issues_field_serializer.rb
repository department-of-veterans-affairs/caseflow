# frozen_string_literal: true

module IssuesFieldSerializer do
	def issues(object)
		IssueSerializer.new(object.active_request_issues_or_decision_isssues, is_collection: true)
									 .serializable_hash[:data].collect{ |issue| issue[:attributes] }
	end
end
