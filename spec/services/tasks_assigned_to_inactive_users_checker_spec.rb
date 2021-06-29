# frozen_string_literal: true

describe TasksAssignedToInactiveUsersChecker, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
  let!(:appeal_with_all_tasks_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    hearing_task = create(:hearing_task, parent: appeal.root_task)
    create(:schedule_hearing_task, parent: hearing_task)
    appeal.root_task.descendants.each(&:on_hold!)
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
    appeal.tasks.open.find_by(type: :PrivacyActTask).assigned_to.inactive!
    appeal
  end
  let!(:appeal_with_closed_root_open_child) do
    appeal = create(:appeal, :with_post_intake_tasks)
    appeal.root_task.completed!
    appeal
  end

  describe "#call" do
    it "reports 1 appeals stuck" do
      subject.call
binding.pry
      expect(subject.report?).to eq(true)
      inactive_task_ids = [
        appeal_with_fully_on_hold_subtree.tasks.open.find_by(type: :PrivacyActTask).id
      ]
      expect(subject.report).to include(inactive_task_ids.join(","))
    end
  end
end
