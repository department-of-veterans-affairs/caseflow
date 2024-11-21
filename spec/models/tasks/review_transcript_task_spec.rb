# frozen_string_literal: true

describe ReviewTranscriptTask, :all_dbs do
  describe "creation" do
    let(:user) { create(:user) }
    let(:appeal) { create(:appeal) }
    let(:org) { create(:organization) }

    it "can be assigned to user" do
      task = ReviewTranscriptTask.create(
        appeal: appeal,
        parent: appeal.root_task,
        assigned_to: user
      )

      expect(task).to be_a(ReviewTranscriptTask)
      expect(task.appeal).to eq(appeal)
      expect(task.parent).to eq(appeal.root_task)
      expect(task.assigned_to_id).to eq(user.id)
    end

    it "can be assigned to organization" do
      task = ReviewTranscriptTask.create(
        appeal: appeal,
        parent: appeal.root_task,
        assigned_to: org
      )

      expect(task).to be_a(ReviewTranscriptTask)
      expect(task.appeal).to eq(appeal)
      expect(task.parent).to eq(appeal.root_task)
      expect(task.assigned_to_id).to eq(org.id)
    end
  end
end
