# frozen_string_literal: true

describe WorkQueue::BoardGrantEffectuationTaskSerializer, :postgres do
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:veteran) { create(:veteran) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }

  let(:task) { create(:board_grant_effectuation_task, appeal: appeal, assigned_to: non_comp_org) }

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      serializable_hash = {
        id: task.id.to_s,
        type: :board_grant_effectuation_task,
        attributes: {
          claimant: { name: appeal.veteran_full_name, relationship: "self" },
          appeal: { id: appeal.external_id, isLegacyAppeal: false, issueCount: 0, activeRequestIssues: [] },
          veteran_participant_id: veteran.participant_id,
          veteran_ssn: veteran.ssn,
          assigned_on: task.assigned_at,
          assigned_at: task.assigned_at,
          closed_at: task.closed_at,
          started_at: task.started_at,
          tasks_url: "/decision_reviews/nco",
          id: task.id,
          created_at: task.created_at,
          issue_count: 0,
          issue_types: "",
          type: "Board Grant",
          external_appeal_id: task.appeal.uuid,
          appeal_type: "Appeal",
          business_line: non_comp_org.url
        }
      }
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end

    context "decision review has no claimants with names" do
      let(:appeal) do
        create(
          :appeal,
          veteran_file_number: veteran.file_number,
          veteran_is_not_claimant: true,
          claimants: []
        )
      end

      it "returns placeholder 'Unknown'" do
        serializable_hash = {
          id: task.id.to_s,
          type: :board_grant_effectuation_task,
          attributes: {
            claimant: { name: "claimant", relationship: "Unknown" },
            appeal: { id: appeal.external_id, isLegacyAppeal: false, issueCount: 0, activeRequestIssues: [] },
            veteran_participant_id: veteran.participant_id,
            veteran_ssn: veteran.ssn,
            assigned_on: task.assigned_at,
            assigned_at: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            id: task.id,
            created_at: task.created_at,
            issue_count: 0,
            issue_types: "",
            type: "Board Grant",
            external_appeal_id: task.appeal.uuid,
            appeal_type: "Appeal",
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

      let(:appeal) do
        build(:appeal,
              veteran_file_number: veteran.file_number,
              claimants: [claimant],
              veteran_is_not_claimant: true)
      end

      it "returns relationship based on claimant class" do
        serializable_hash = {
          id: task.id.to_s,
          type: :board_grant_effectuation_task,
          attributes: {
            claimant: { name: claimant.name, relationship: "Veteran" },
            appeal: { id: appeal.external_id, isLegacyAppeal: false, issueCount: 0, activeRequestIssues: [] },
            veteran_participant_id: veteran.participant_id,
            veteran_ssn: veteran.ssn,
            assigned_on: task.assigned_at,
            assigned_at: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            id: task.id,
            created_at: task.created_at,
            issue_count: 0,
            issue_types: "",
            type: "Board Grant",
            external_appeal_id: task.appeal.uuid,
            appeal_type: "Appeal",
            business_line: non_comp_org.url
          }
        }
        expect(subject.serializable_hash[:data]).to eq(serializable_hash)
      end
    end
  end
end
