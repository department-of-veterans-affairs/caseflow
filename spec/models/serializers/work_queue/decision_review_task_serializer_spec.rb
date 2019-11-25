# frozen_string_literal: true

describe WorkQueue::DecisionReviewTaskSerializer, :postgres do
  let(:veteran) { create(:veteran) }
  let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:task) { create(:higher_level_review_task, appeal: hlr, assigned_to: non_comp_org) }

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      serializable_hash = {
        id: task.id.to_s,
        type: :decision_review_task,
        attributes: {
          claimant: { name: hlr.veteran_full_name, relationship: "self" },
          appeal: { id: hlr.id.to_s, isLegacyAppeal: false, issueCount: 0, activeRequestIssues: [] },
          veteran_participant_id: veteran.participant_id,
          assigned_on: task.assigned_at,
          closed_at: task.closed_at,
          started_at: task.started_at,
          tasks_url: "/decision_reviews/nco",
          id: task.id,
          created_at: task.created_at,
          type: "Higher-Level Review"
        }
      }
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end

    context "decision review has no claimants with names" do
      let(:hlr) do
        create(:higher_level_review, veteran_file_number: veteran.file_number, veteran_is_not_claimant: true)
      end

      it "returns placeholder 'claimant'" do
        serializable_hash = {
          id: task.id.to_s,
          type: :decision_review_task,
          attributes: {
            claimant: { name: "claimant", relationship: "claimant" },
            appeal: { id: hlr.id.to_s, isLegacyAppeal: false, issueCount: 0, activeRequestIssues: [] },
            veteran_participant_id: veteran.participant_id,
            assigned_on: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            id: task.id,
            created_at: task.created_at,
            type: "Higher-Level Review"
          }
        }
        expect(subject.serializable_hash[:data]).to eq(serializable_hash)
      end
    end

    context "decision review has one claimant with name but no relationship" do
      let(:claimant) do
        claimant = create(:claimant)
        allow(claimant).to receive(:relationship) {}
        claimant
      end

      let(:hlr) do
        create(:higher_level_review,
               veteran_file_number: veteran.file_number,
               claimants: [claimant],
               veteran_is_not_claimant: true)
      end

      it "returns placeholder 'claimant'" do
        serializable_hash = {
          id: task.id.to_s,
          type: :decision_review_task,
          attributes: {
            claimant: { name: claimant.name, relationship: "claimant" },
            appeal: { id: hlr.id.to_s, isLegacyAppeal: false, issueCount: 0, activeRequestIssues: [] },
            veteran_participant_id: veteran.participant_id,
            assigned_on: task.assigned_at,
            closed_at: task.closed_at,
            started_at: task.started_at,
            tasks_url: "/decision_reviews/nco",
            id: task.id,
            created_at: task.created_at,
            type: "Higher-Level Review"
          }
        }
        expect(subject.serializable_hash[:data]).to eq(serializable_hash)
      end
    end
  end
end
