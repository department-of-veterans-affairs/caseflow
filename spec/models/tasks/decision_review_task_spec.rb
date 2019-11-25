# frozen_string_literal: true

describe DecisionReviewTask, :postgres do
  include IntakeHelpers

  let(:benefit_type) { "education" }

  describe "#label" do
    subject { create(:higher_level_review_task) }

    it "uses the review_title of the parent appeal" do
      expect(subject.label).to eq "Higher-Level Review"
    end
  end

  describe "#complete_with_payload!" do
    before do
      setup_prior_claim_with_payee_code(hlr, veteran, "00")
    end

    let(:veteran) { create(:veteran) }
    let(:hlr) do
      create(
        :higher_level_review,
        number_of_claimants: 1,
        veteran_file_number: veteran.file_number,
        benefit_type: benefit_type
      )
    end
    let(:trait) { :assigned }
    let!(:request_issues) do
      [
        create(:request_issue, :rating, decision_review: hlr, benefit_type: benefit_type),
        create(:request_issue, :rating, decision_review: hlr, benefit_type: benefit_type),
        create(:request_issue, :nonrating, decision_review: hlr, benefit_type: benefit_type),
        create(:request_issue, :removed, decision_review: hlr, benefit_type: benefit_type)
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
        },
        {
          request_issue_id: request_issues.third.id,
          description: "description 3",
          disposition: "DTA Error",
          decision_date: decision_date
        }
      ]
    end
    let(:task) { create(:higher_level_review_task, trait, appeal: hlr) }
    subject { task.complete_with_payload!(decision_issue_params, decision_date) }

    context "assigned task" do
      it "can be completed" do
        expect(subject).to eq true
        caseflow_decision_date = Date.parse(decision_date).in_time_zone(Time.zone)
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
        expect(DecisionIssue.find_by(
                 decision_review: hlr,
                 description: "description 3",
                 disposition: "DTA Error",
                 caseflow_decision_date: caseflow_decision_date
               )).to_not be_nil
        expect(task.status).to eq "completed"

        remand_sc = hlr.remand_supplemental_claims.first
        expect(remand_sc).to_not be_nil
        expect(remand_sc.request_issues.first.contested_issue_description).to eq("description 3")
      end
    end

    context "completed task" do
      let(:trait) { :completed }

      it "cannot be completed again" do
        expect(subject).to eq false
        expect(DecisionIssue.all.length).to eq 0
      end
    end
  end
end
