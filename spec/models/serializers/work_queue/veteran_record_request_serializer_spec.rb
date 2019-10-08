# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe WorkQueue::VeteranRecordRequestSerializer, :postgres do
  let(:veteran) { create(:veteran) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
  let(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:task) { create(:veteran_record_request_task, appeal: appeal, assigned_to: non_comp_org) }

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      serializable_hash = {
        id: task.id.to_s,
        type: :veteran_record_request,
        attributes: {
          claimant: { name: appeal.veteran_full_name, relationship: "self" },
          appeal: { id: appeal.uuid.to_s, isLegacyAppeal: false, issueCount: 0 },
          veteran_participant_id: veteran.participant_id,
          assigned_on: task.assigned_at,
          closed_at: task.closed_at,
          started_at: task.started_at,
          tasks_url: "/decision_reviews/nco",
          id: task.id,
          created_at: task.created_at,
          type: "Record Request"
        }
      }
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end
  end
end
