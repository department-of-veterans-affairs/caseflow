describe DecisionReviewTask do
  let(:benefit_type) { "education" }

  describe "#label" do
    subject { create(:higher_level_review_task).becomes(described_class) }

    it "uses the review_title of the parent appeal" do
      expect(subject.label).to eq "Higher-Level Review"
    end
  end

  describe "#complete_with_payload!" do
    let(:veteran) { create(:veteran) }
    let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number, benefit_type: benefit_type) }
    let(:task_status) { "assigned" }
    let!(:request_issues) do
      [
        create(:request_issue, :rating, review_request: hlr, benefit_type: benefit_type),
        create(:request_issue, :rating, review_request: hlr, benefit_type: benefit_type)
      ]
    end
    let(:decision_date) { "01/01/2019" }
    let(:decision_issue_params) do
      [
        {
          request_issue_id: request_issues.first.id,
          description: "description 1",
          disposition: "GRANTED",
          decision_date: decision_date
        },
        {
          request_issue_id: request_issues.second.id,
          description: "description 2",
          disposition: "DENIED",
          decision_date: decision_date
        }
      ]
    end
    let(:task) { create(:task, appeal: hlr, status: task_status).becomes(described_class) }
    subject { task.complete_with_payload!(decision_issue_params, decision_date) }

    context "assigned task" do
      it "can be completed" do
        expect(subject).to eq true
        caseflow_decision_date = Date.parse(decision_date).to_datetime
        expect(DecisionIssue.find_by(
                 decision_review: hlr,
                 description: "description 1",
                 disposition: "GRANTED",
                 caseflow_decision_date: caseflow_decision_date
               )).to_not be_nil
        expect(DecisionIssue.find_by(
                 decision_review: hlr,
                 description: "description 2",
                 disposition: "DENIED",
                 caseflow_decision_date: caseflow_decision_date
               )).to_not be_nil
        expect(task.status).to eq "completed"
      end
    end

    context "completed task" do
      let(:task_status) { "completed" }

      it "cannot be completed again" do
        expect(subject).to eq false
        expect(DecisionIssue.all.length).to eq 0
      end
    end
  end
end
