# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe AppealsWithNoTasksOrAllTasksOnHoldQuery, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
  let!(:appeal_with_all_tasks_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    hearing_task = create(:hearing_task, appeal: appeal, parent: appeal.root_task)
    schedule_hearing_task = create(:schedule_hearing_task, appeal: appeal, parent: hearing_task)
    appeal.root_task.descendants.each(&:on_hold!)
    appeal
  end
  let!(:appeal_with_decision_documents) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:decision_document, appeal: appeal)
    appeal
  end

  describe "#call" do
    subject { described_class.new.call }

    it "returns array of appeals that look stuck" do
      expect(subject).to match_array([appeal_with_zero_tasks, appeal_with_all_tasks_on_hold])
    end
  end
end
