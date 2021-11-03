# frozen_string_literal: true

describe OpenTasksWithClosedAtChecker, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let!(:task) do
    task = create(:task, :assigned, appeal: create(:appeal))
    task.update!(closed_at: Time.zone.now)
    task
  end

  let!(:open_task_with_closed_parent) do
    appeal = create(:appeal)
    parent = create(:task, appeal: appeal)
    task = create(:task, :assigned, parent: parent)
    parent.update!(closed_at: Time.zone.now, status: :completed)
    task
  end

  describe "#call" do
    it "reports one Task in bad state" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/1 open Task with a closed_at value/)
      expect(subject.report).to match(/1 open Task with a closed parent Task/)
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
          expect(subject.report).to match(/1 open Task with a closed_at value/)
          expect(subject.report).to match(/1 open Task with a closed parent Task/)
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
          expect(subject.report).to match(/1 open Task with a closed_at value/)
          expect(subject.report).to match(/1 open Task with a closed parent Task/)
        end
      end
    end
  end
end
