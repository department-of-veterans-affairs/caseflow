# frozen_string_literal: true

class Api::V3::External::VeteransController < Api::V3::BaseController
  def decision_reviews
    @veteran = Veteran.find(params[:id])
    req_issues = RequestIssue.where(veteran_participant_id: @veteran.participant_id)

    test_issues = []
    req_issues.each do |request_issue|
      combined_issue = {}
      test_issue = TestIssue.new

      combined_issue.merge!(request_issue.attributes)

      if request_issue.decision_issues.any?
        combined_issue.merge!(request_issue.decision_issues.first.attributes)
      end

      combined_issue.each do |key, value|
        if test_issue.respond_to?("#{key}=")
          test_issue.send("#{key}=", value)
        end
      end
      test_issues << test_issue
    end

    render json: test_issues
  end

end
