# frozen_string_literal: true

describe StuckAppealsChecker, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
  let!(:appeal_with_all_tasks_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    hearing_task = create(:hearing_task, parent: appeal.root_task)
    create(:schedule_hearing_task, parent: hearing_task)
    appeal.root_task.descendants.each(&:on_hold!)
    appeal
  end
  let!(:appeal_with_decision_documents) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:decision_document, appeal: appeal)
    appeal
  end
  let!(:dispatched_appeal_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:bva_dispatch_task, :completed, appeal: appeal)
    appeal
  end
  let!(:appeal_with_closed_root_open_child) do
    appeal = create(:appeal, :with_post_intake_tasks)
    appeal.root_task.completed!
    appeal
  end

  describe "#call" do
    it "reports 3 appeals stuck" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/AppealsWithNoTasksOrAllTasksOnHoldQuery: 3/)
      expect(subject.report).to match(/AppealsWithClosedRootTaskOpenChildrenQuery: 1/)
    end
  end
end
