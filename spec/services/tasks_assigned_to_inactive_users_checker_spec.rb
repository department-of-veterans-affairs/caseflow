# frozen_string_literal: true

describe TasksAssignedToInactiveUsersChecker, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
  let!(:dispatched_appeal_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:bva_dispatch_task, :completed, appeal: appeal)
    appeal
  end
  let!(:appeal_with_fully_on_hold_subtree) do
    appeal = create(:appeal, :with_post_intake_tasks)
    task = create(:privacy_act_task, parent: appeal.root_task)
    task.descendants.each(&:on_hold!)
    task.assigned_to.inactive!
    appeal
  end
  let!(:appeal_with_closed_root_open_child) do
    appeal = create(:appeal, :with_post_intake_tasks)
    appeal.root_task.completed!
    task = create(:docket_switch_mail_task, parent: appeal.root_task, assigned_to: create(:user))
    task.assigned_to.inactive!
    appeal
  end

  describe "#call" do
    it "reports 1 appeals stuck" do
      subject.call
      expect(subject.report?).to eq(true)

      inactive_tasks = [
        appeal_with_fully_on_hold_subtree.tasks.open.find_by(type: :PrivacyActTask),
        appeal_with_closed_root_open_child.tasks.open.find_by(type: :DocketSwitchMailTask)
      ]
      expect(subject.inactive_tasks).to match_array(inactive_tasks)
      expect(subject.report).to match(/#{inactive_tasks[0].type}, .*#{inactive_tasks[0].id}/)
      expect(subject.report).to match(/#{inactive_tasks[1].type}, .*#{inactive_tasks[1].id}/)
    end
  end
end
