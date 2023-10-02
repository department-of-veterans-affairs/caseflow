# frozen_string_literal: true

class Api::V3::External::IssueMerger < Api::V3::BaseController
  def self.merge(veteran)
    req_issues = RequestIssue.where(veteran_participant_id: veteran.participant_id,
                                    benefit_type: %w[compensation pension fiduciary])
    test_issues = []
    req_issues.each { |request_issue| merge_attributes(request_issue, test_issues) }
    render json: test_issues
  end

  def self.merge_attributes(request_issue, test_issues)
    combined_issue = {}
    test_issue = TestIssue.new

    combined_issue.merge!(request_issue.attributes)

    if request_issue.decision_issues.any?
      decision_issue = request_issue.decision_issues.first
      combined_issue.merge!(decision_issue.attributes)
      combined_issue[:request_issue_id] = request_issue.id
      combined_issue[:decision_issue_id] = decision_issue.id
    end

    combined_issue.each do |key, value|
      if test_issue.respond_to?("#{key}=")
        test_issue.send("#{key}=", value)
      end
    end
    test_issues << test_issue
  end
end
