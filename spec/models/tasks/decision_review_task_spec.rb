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
        veteran_file_number: veteran.file_number,
        benefit_type: benefit_type,
        claimant_type: :veteran_claimant
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

  shared_context "decision review task assigned to business line" do
    let(:veteran) { create(:veteran) }
    let(:hlr) do
      create(:higher_level_review, claimant_type: :veteran_claimant, veteran_file_number: veteran.file_number)
    end
    let(:business_line) { create(:business_line, name: "National Cemetery Administration", url: "nca") }

    let(:decision_review_task) { create(:higher_level_review_task, appeal: hlr, assigned_to: business_line) }
  end

  describe "#ui_hash" do
    include_context "decision review task assigned to business line"

    subject { decision_review_task.ui_hash }

    it "includes only key-values within serialize_task[:data][:attributes]" do
      serialized_hash = {
        appeal: {
          id: hlr.id.to_s,
          isLegacyAppeal: false,
          issueCount: 0,
          activeRequestIssues: [],
          appellant_type: "VeteranClaimant",
          uuid: hlr.uuid
        },
        power_of_attorney: power_of_attorney,
        appellant_type: "VeteranClaimant",
        started_at: decision_review_task.started_at,
        tasks_url: business_line.tasks_url,
        id: decision_review_task.id,
        created_at: decision_review_task.created_at,
        veteran_participant_id: veteran.participant_id,
        veteran_ssn: veteran.ssn,
        closed_at: decision_review_task.closed_at,
        assigned_on: decision_review_task.assigned_at,
        assigned_at: decision_review_task.assigned_at,
        issue_count: 0,
        issue_types: "",
        type: "Higher-Level Review",
        claimant: { name: hlr.veteran_full_name, relationship: "self" },
        business_line: business_line.url,
        has_poa: true
      }
      expect(subject).to eq serialized_hash
      expect(subject.key?(:attributes)).to eq false
    end
  end

  describe "#serialize_task" do
    include_context "decision review task assigned to business line"

    subject { decision_review_task.serialize_task }

    it "includes all key-values within serialize_task[:data]" do
      serialized_hash = {
        id: decision_review_task.id.to_s,
        type: :decision_review_task,
        attributes: {
          claimant: { name: hlr.veteran_full_name, relationship: "self" },
          appeal: {
            id: hlr.id.to_s,
            isLegacyAppeal: false,
            issueCount: 0,
            activeRequestIssues: [],
            uuid: hlr.uuid,
            appellant_type: "VeteranClaimant"
          },
          appellant_type: "VeteranClaimant",
          power_of_attorney: power_of_attorney,
          veteran_participant_id: veteran.participant_id,
          veteran_ssn: veteran.ssn,
          assigned_on: decision_review_task.assigned_at,
          assigned_at: decision_review_task.assigned_at,
          closed_at: decision_review_task.closed_at,
          started_at: decision_review_task.started_at,
          tasks_url: business_line.tasks_url,
          id: decision_review_task.id,
          created_at: decision_review_task.created_at,
          issue_count: 0,
          issue_types: "",
          type: "Higher-Level Review",
          business_line: business_line.url,
          has_poa: true
        }
      }

      expect(subject).to eq serialized_hash
      expect(subject.key?(:attributes)).to eq true
    end
  end

  def power_of_attorney
    {
      representative_type: decision_review_task.appeal.representative_type,
      representative_name: decision_review_task.appeal.representative_name,
      representative_address: decision_review_task.appeal.representative_address,
      representative_email_address: decision_review_task.appeal.representative_email_address,
      representative_tz: decision_review_task.appeal.representative_tz,
      poa_last_synced_at: decision_review_task.appeal.poa_last_synced_at
    }
  end
end
