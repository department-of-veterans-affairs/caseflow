# frozen_string_literal: true

describe Seeds::DecisionIssues do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates a decision issue with a decision date in the future" do
      expect { subject }.to_not raise_error
      veteran = Veteran.find_by(first_name: "Veteran", last_name: "DecisionIssues")
      appeal = Appeal.find_by(veteran_file_number: veteran.file_number)
      decision_issue = appeal.decision_issues[0]
      expect(decision_issue.caseflow_decision_date).to be > Time.zone.now
    end
  end
end
