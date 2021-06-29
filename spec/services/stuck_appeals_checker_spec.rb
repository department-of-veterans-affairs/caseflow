# frozen_string_literal: true

describe StuckAppealsChecker, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
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
  let!(:appeal_with_fully_on_hold_subtree) do
    appeal = create(:appeal, :with_post_intake_tasks)
    task = create(:privacy_act_task, appeal: appeal, parent: appeal.root_task)
    task.descendants.each(&:on_hold!)
    appeal
  end
  let!(:appeal_with_closed_root_open_child) do
    appeal = create(:appeal, :with_post_intake_tasks)
    appeal.root_task.completed!
    appeal
  end

  describe "#call" do
    it "reports 5 appeals stuck" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/AppealsWithNoTasksOrAllTasksOnHoldQuery: 4/)
      expect(subject.report).to match(/AppealsWithClosedRootTaskOpenChildrenQuery: 1/)
    end
  end
end
