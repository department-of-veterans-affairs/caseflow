# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

##
# This RSpec provides an example of how to backfill
# (i.e., retroactively add missing data to) an AMA appeal.
#
# Eample requests from the Board :
# - [Dispatch Task #203](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/203#)
# - [Early Appeal issues #118](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/118)

describe "Backfill early AMA appeal" do
  context "given Appeal with only a RootTask" do
    let(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/early-appeal-39.json", verbosity: 0)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    let(:judge) { User.find_by_css_id("PSIMPSONBVAA").tap { |user| create(:staff, :judge_role, user: user) } }
    let(:atty) { User.find_by_css_id("BRANDAUBVAE").tap { |user| create(:staff, :attorney_role, user: user) } }
    let!(:bva_dispatch_user) { create(:user).tap { |user| BvaDispatch.singleton.add_user(user) } }

    let(:dispatch_date) { Time.zone.local(2019, 1, 9, 12) } # use noon time to leave room for earlier task activity
    let(:judge_review_date) { dispatch_date - 1.hour }
    let(:atty_draft_date) { dispatch_date - 2.hours }

    it "creates tasks and other records associated with a dispatched appeal" do
      expect(BVAAppealStatus.new(appeal: appeal).status).to eq :unknown # We will fix this
      expect(appeal.root_task.status).to eq "completed"

      # 1. Create tasks to associate appeal with a judge and attorney
      judge_review_task = JudgeDecisionReviewTask.create!(appeal: appeal, parent: appeal.root_task,
                                                          assigned_to: judge,
                                                          assigned_at: judge_review_date - 30.minutes,
                                                          started_at: judge_review_date - 30.minutes,
                                                          instructions: ["Retroactively created task."])
      attorney_task = AttorneyTask.create!(appeal: appeal, parent: judge_review_task,
                                           assigned_by: judge,
                                           assigned_to: atty,
                                           assigned_at: atty_draft_date - 30.minutes,
                                           started_at: atty_draft_date - 30.minutes,
                                           instructions: ["Retroactively created task."])
      appeal.reload.treee :id, :status, :ASGN_BY, :ASGN_TO, :started_at, :assigned_at, :closed_at

      attorney_task.completed!
      attorney_task.update(closed_at: atty_draft_date)
      expect(attorney_task.assigned_to).to eq atty
      expect(attorney_task.closed_at).to eq atty_draft_date
      expect(attorney_task.status).to eq "completed"
      expect(attorney_task.assigned_at).to eq (atty_draft_date - 30.minutes)
      expect(attorney_task.started_at).to eq (atty_draft_date - 30.minutes)

      judge_review_task.completed!
      judge_review_task.update(assigned_at: judge_review_date - 30.minutes,
                               placed_on_hold_at: judge_review_date - 30.minutes,
                               closed_at: judge_review_date)
      expect(judge_review_task.assigned_to).to eq judge
      expect(judge_review_task.closed_at).to eq judge_review_date
      expect(judge_review_task.status).to eq "completed"
      expect(judge_review_task.assigned_at).to eq (judge_review_date - 30.minutes)
      expect(judge_review_task.started_at).to eq (judge_review_date - 30.minutes)

      # 2. Create BvaDispatchTask
      org_dispatch_task = BvaDispatchTask.create!(appeal: appeal,
                                                  assigned_to: BvaDispatch.singleton,
                                                  parent: appeal.root_task)
      # Since the actual BvaDispatch user could not be deduced, delete the child task.
      # If the user is known, set assigned_to and dates accordingly.
      org_dispatch_task.children.delete_all
      org_dispatch_task.completed!
      org_dispatch_task.update(assigned_at: dispatch_date - 30.minutes,
                               placed_on_hold_at: dispatch_date - 30.minutes,
                               closed_at: dispatch_date)
      expect(org_dispatch_task.status).to eq "completed"
      expect(org_dispatch_task.assigned_at).to eq (dispatch_date - 30.minutes)

      appeal.reload.treee :id, :status, :ASGN_BY, :ASGN_TO, :started_at, :assigned_at, :placed_on_hold_at, :closed_at
      expect(appeal.root_task.status).to eq "completed"

      # 3. Create DecisionIssues for each RequestIssue -- see (Bat-Team-Quick-Ref#split-decision-issues)
      req_issues = appeal.request_issues.order(:id) # This is the same order as presented on the Case Details page
      expect(req_issues.pluck(:id)).to eq [2000000024, 2000000025, 2000000026, 2000000027]

      # Check the decision document for the appeal by going to Case Details, looking at when the case was dispatched,
      # then looking at the veteran's Reader docs for a "BVA Decision" document with a similar date.
      # List all such docs with: `appeal.documents.where(type: "BVA Decision").pluck(:received_at, :type).sort`
      # Tip: download the PDF to copy and paste the decision text for all issues. 
      # Issue descriptions are not considered PII unless they contain PII (e.g., a name or address).

      # Use `req_issues.pluck(:contested_issue_description)` to map to decision in the "BVA Decision" document
      # and populate the following to be used to create DecisionIssues:
      descriptions = [
        "Decision for insomnia disorder issue is denied. <Pasted decision from decision doc>",
        "Service connection for eczema is denied. <Pasted decision from decision doc>",
        "Service connection for gastroesophageal reflux disease (GERD) is granted. <Pasted decision from decision doc>",
        "Service connection for sleep apnea disorder is remanded. <Pasted decision from decision doc>"
      ]
      dispositions = ["denied", "denied", "allowed", "remanded"]
      # See Case Details page for Appeal 39 (8c6cc397-6bb9-4673-b94b-908c31c6f419) for full decision description text.
      req_issues.each_with_index do |req_issue, index|
        new_di=DecisionIssue.create!(
          disposition: dispositions[index],
          description: descriptions[index],
          participant_id: appeal.veteran.participant_id,
          decision_review_type: appeal.class.name,
          decision_review_id: appeal.id,
          benefit_type: req_issue.benefit_type,
          diagnostic_code: req_issue.diagnostic_code,
          caseflow_decision_date: dispatch_date.to_date
        )
      
        RequestDecisionIssue.create!(request_issue_id: req_issue.id, decision_issue_id: new_di.id)
      end
      expect(appeal.decision_issues.count).to eq 4
      expect(req_issues.map(&:decision_issues).flatten.pluck(:disposition)).to eq dispositions
      puts IntakeRenderer.render(appeal)
      
      # 4. Create DecisionDocument for the appeal -- also see creating a `DecisionDocument` in fixing_dispatched_appeal_spec.rb
      # Note: this DecisionDocument details were not (yet) provided, so the following is just a made-up example:
      expect(appeal.decision_document).to eq nil
      params = {
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        citation_number: "A19010901",  # presumed format: AYYMMDDcounter
        decision_date: dispatch_date.to_date,
        # presumed format: ...\archYYMM\citation_number
        redacted_document_location: "\\\\vacohsm01.dva.va.gov\\vaco_workgroups\\BVA\\archdata\\arch1901\\A19010999.txt",
      }
      decision_doc = DecisionDocument.create!(params)
      expect(appeal.decision_document).to eq decision_doc

      binding.pry
    end
  end
end
