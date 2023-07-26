# frozen_string_literal: true

describe WorkQueue::DecisionReviewTaskSerializer, :postgres do
  let(:veteran) { create(:veteran) }
  let(:claimant_type) { :none }
  let(:hlr) do
    create(:higher_level_review,
           benefit_type: nil,
           veteran_file_number: veteran.file_number,
           claimant_type: claimant_type)
  end
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:task) { create(:higher_level_review_task, appeal: hlr, assigned_to: non_comp_org) }

  subject { described_class.new(task) }

  describe "#as_json" do
    let(:claimant_type) { :veteran_claimant }
    it "renders ready for client consumption" do
      serializable_hash = {
        id: task.id.to_s,
        type: :decision_review_task,
        attributes: {
          claimant: { name: hlr.veteran_full_name, relationship: "self" },
          appeal: {
            id: hlr.id.to_s,
            isLegacyAppeal: false,
            issueCount: 0,
            activeRequestIssues: [],
            uuid: task.appeal.uuid,
            appellant_type: nil
          },
          power_of_attorney: hlr.claimant&.power_of_attorney,
          veteran_ssn: veteran.ssn,
          veteran_participant_id: veteran.participant_id,
          assigned_on: task.assigned_at,
          assigned_at: task.assigned_at,
          closed_at: task.closed_at,
          started_at: task.started_at,
          appellant_type: nil,
          tasks_url: "/decision_reviews/nco",
          id: task.id,
          created_at: task.created_at,
          issue_count: 0,
          issue_types: "",
          type: "Higher-Level Review",
          business_line: non_comp_org.url
        }
      }
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end

    context "decision review has no claimants with names" do
      let(:hlr) do
        create(:higher_level_review, veteran_file_number: veteran.file_number, veteran_is_not_claimant: true)
      end

      it "returns placeholder 'Unknown'" do
        serializable_hash = {
          id: task.id.to_s,
          type: :decision_review_task,
          attributes: {
            claimant: { name: "claimant", relationship: "Unknown" },
            appeal: {
              id: hlr.id.to_s,
              isLegacyAppeal: false,
              issueCount: 0,
              activeRequestIssues: [],
              uuid: task.appeal.uuid,
              appellant_type: nil
            },
            power_of_attorney: hlr.claimant&.power_of_attorney,
            veteran_ssn: veteran.ssn,
            veteran_participant_id: veteran.participant_id,
            assigned_on: task.assigned_at,
            assigned_at: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            id: task.id,
            created_at: task.created_at,
            appellant_type: nil,
            issue_count: 0,
            issue_types: "",
            type: "Higher-Level Review",
            business_line: non_comp_org.url
          }
        }
        expect(subject.serializable_hash[:data]).to eq(serializable_hash)
      end
    end

    context "decision review has one claimant with name but no relationship" do
      let(:claimant) do
        claimant = build(:claimant, payee_code: "00")
        allow(claimant).to receive(:relationship) {}
        claimant
      end

      let(:hlr) do
        build(:higher_level_review,
              veteran_file_number: veteran.file_number,
              claimants: [claimant],
              veteran_is_not_claimant: true)
      end

      it "returns relationship based on claimant class" do
        serializable_hash = {
          id: task.id.to_s,
          type: :decision_review_task,
          attributes: {
            claimant: { name: claimant.name, relationship: "Veteran" },
            appeal: {
              id: hlr.id.to_s,
              isLegacyAppeal: false,
              issueCount: 0,
              activeRequestIssues: [],
              uuid: task.appeal.uuid,
              appellant_type: claimant.type
            },
            veteran_ssn: veteran.ssn,
            power_of_attorney: {
              representative_address: hlr.claimant.power_of_attorney&.representative_address,
              representative_email_address: hlr.claimant.power_of_attorney&.representative_email_address,
              representative_name: hlr.claimant.power_of_attorney&.representative_name,
              representative_type: hlr.claimant.power_of_attorney&.representative_type
            },
            veteran_participant_id: veteran.participant_id,
            assigned_on: task.assigned_at,
            assigned_at: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            appellant_type: nil,
            id: task.id,
            created_at: task.created_at,
            issue_count: 0,
            issue_types: "",
            type: "Higher-Level Review",
            business_line: non_comp_org.url
          }
        }
        # byebug
        expect(subject.serializable_hash[:data]).to eq(serializable_hash)
      end
    end

    context "decision review with multiple issues with multiple issue categories" do
      let(:claimant_type) { :veteran_claimant }
      let(:benefit_type) { "vha" }
      let!(:vha_org) { create(:business_line, name: "Veterans Health Administration", url: "vha") }
      let(:request_issues) do
        [
          create(:request_issue, benefit_type: "vha", nonrating_issue_category: "Beneficiary Travel"),
          create(:request_issue, benefit_type: "vha", nonrating_issue_category: "Caregiver | Eligibility")
        ]
      end

      before do
        hlr.request_issues.push(*request_issues)
      end

      it "returns issue_count and issue_types as a comma delimited list" do
        serialized_issues = hlr.request_issues.active.map(&:serialize)
        serializable_hash = {
          id: task.id.to_s,
          type: :decision_review_task,
          attributes: {
            claimant: { name: hlr.veteran_full_name, relationship: "self" },
            appeal: { id: hlr.id.to_s, isLegacyAppeal: false, issueCount: 2, activeRequestIssues: serialized_issues },
            veteran_ssn: hlr.veteran.ssn,
            power_of_attorney: nil,
            veteran_participant_id: hlr.veteran.participant_id,
            assigned_on: task.assigned_at,
            assigned_at: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            id: task.id,
            created_at: task.created_at,
            issue_count: 2,
            issue_types: hlr.request_issues.active.pluck(:nonrating_issue_category).join(","),
            type: "Higher-Level Review",
            business_line: non_comp_org.url,
            appellant_type: nil
          }
        }
        expect(subject.serializable_hash[:data]).to eq(serializable_hash)
      end
    end
  end
end
