
class DecisionDateChecker < DataIntegrityChecker
    def call
        appeal_ids = request_issues_without_decision_date
        build_report(appeal_ids)
    end 

    def slack_channel
        "#appeals-foxtrot"
    end

    private

    def request_issues_without_decision_date
        issues_without_decision_date = RequestIssue.where.not(nonrating_issue_category: nil).where(decision_date: nil, closed_at: nil).map(&:id) 
        issues_without_decision_date
    end

    def build_report(appeal_ids)
        return if appeal_ids.empty?

        ids = appeal_ids.sort
        count = appeal_ids.length
        
        add_to_report "Found #{count} Non-Rating Issues without decision date"
        add_to_report "RequestIssue.where(id: #{ids})"
    end

end
