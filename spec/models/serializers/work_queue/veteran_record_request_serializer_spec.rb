# frozen_string_literal: true

describe WorkQueue::VeteranRecordRequestSerializer, :postgres do
  let(:veteran) { create(:veteran) }
  let(:appeal) { create(:appeal, :with_request_issues, issue_count: 1, veteran_file_number: veteran.file_number) }
  let(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:task) { create(:veteran_record_request_task, appeal: appeal, assigned_to: non_comp_org) }
  let(:appeal_vet_not_claimant) { create(:appeal, number_of_claimants: 1, veteran_is_not_claimant: true) }
  let(:task_vet_not_claimant) do
    create(:veteran_record_request_task, appeal: appeal_vet_not_claimant, assigned_to: non_comp_org)
  end

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      serializable_hash = {
        id: task.id.to_s,
        type: :veteran_record_request,
        attributes: {
          claimant: { name: appeal.veteran_full_name, relationship: "self" },
          appeal: { id: appeal.uuid.to_s, isLegacyAppeal: false, issueCount: appeal.request_issues.count },
          veteran_participant_id: veteran.participant_id,
          assigned_on: task.assigned_at,
          assigned_at: task.assigned_at,
          closed_at: task.closed_at,
          started_at: task.started_at,
          tasks_url: "/decision_reviews/nco",
          id: task.id,
          created_at: task.created_at,
          issue_count: appeal.request_issues.count,
          type: "Record Request",
          business_line: non_comp_org.url

        }
      }
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end
  end

  describe "class methods" do
    it "correctly sets claimant name and relationship when veteran claimant" do
      expect(described_class.claimant_name(task)).to eq(appeal.claimant.name)
      expect(described_class.claimant_relationship(task)).to eq("self")
    end

    it "correctly sets claimant name and relationship when veteran is not claimant" do
      expect(described_class.claimant_name(task_vet_not_claimant))
        .to eq(appeal_vet_not_claimant.claimant.name)
      expect(described_class.claimant_relationship(task_vet_not_claimant))
        .to eq(appeal_vet_not_claimant.claimant.relationship)
    end
  end
end
