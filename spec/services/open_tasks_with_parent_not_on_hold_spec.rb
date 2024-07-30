# frozen_string_literal: true

describe OpenTasksWithParentNotOnHold, :postgres do
  let!(:valid_task) { create(:task, :assigned, appeal: create(:appeal)) }

  let!(:open_task_with_closed_parent) do
    appeal = create(:appeal)
    parent = create(:task, appeal: appeal)
    task = create(:task, :assigned, parent: parent)
    parent.update!(closed_at: Time.zone.now, status: :completed)
    task
  end

  let!(:open_task_with_assigned_parent) do
    appeal = create(:appeal)
    parent = create(:task, appeal: appeal)
    task = create(:task, :assigned, parent: parent)
    parent.update!(status: :assigned)
    task
  end

  describe "#call" do
    it "reports one task in bad state" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/2 open tasks with a non-on_hold parent task/)
    end
  end

  describe "with ignored task types" do
    describe "with TrackVeteranTask" do
      let!(:ignored_task_with_closed_root_task_parent) do
        appeal = create(:appeal)
        root_task = create(:root_task, appeal: appeal)
        task = create(:track_veteran_task, :assigned, parent: root_task)
        root_task.update!(closed_at: Time.zone.now, status: :completed)
        task
      end

      it "doesn't report ignored task" do
        subject.call

        # Report still includes the remaining types
        expect(subject.report?).to eq(true)
        expect(subject.report).to match(/2 open tasks with a non-on_hold parent task/)
      end
    end

    describe "with MailTask" do
      let!(:ignored_task_with_closed_root_task_parent) do
        appeal = create(:appeal)
        root_task = create(:root_task, appeal: appeal)
        task = create(:appeal_withdrawal_mail_task, :assigned, parent: root_task)
        root_task.update!(closed_at: Time.zone.now, status: :completed)
        task
      end

      it "doesn't report ignored task" do
        subject.call

        # Report still includes the remaining types
        expect(subject.report?).to eq(true)
        expect(subject.report).to match(/2 open tasks with a non-on_hold parent task/)
      end
    end
  end
end
