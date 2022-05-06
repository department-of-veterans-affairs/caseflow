# frozen_string_literal: true

describe CancelChangeHearingRequestTypeTaskJob do
  let(:job) { CancelChangeHearingRequestTypeTaskJob.new }
  current_time = Time.zone.today
  let(:appeal_one) { create(:appeal, id: 1) }
  let(:appeal_two) { create(:appeal, id: 2) }
  appeal_list = [appeal_one, appeal_two]

  describe "no tasks that need to be cancelled" do
    context "when there's no hearings 10 days before scheduled" do
      subject { job.find_affected_hearings }
      schedule_day = current_time.next_day(11)
      let!(:hearing_day) { create(:hearing_day, scheduled_for: schedule_day) }
      let!(:hearing_one) { create(:hearing, hearing_day: hearing_day, appeal: appeal_one) }
      let!(:hearing_two) { create(:hearing, hearing_day: hearing_day, appeal: appeal_two) }

      it "find_affected_hearings returns empty array" do
        subject

        expect(subject).to eq nil
      end
    end
  end
  describe "tasks that need to be cancelled" do
    schedule_day = current_time.next_day(10)
    let!(:hearing_day) { create(:hearing_day, scheduled_for: schedule_day) }
    let!(:hearing_one) { create(:hearing, hearing_day: hearing_day, appeal: appeal_one) }
    let!(:hearing_two) { create(:hearing, hearing_day: hearing_day, appeal: appeal_two) }
    context "when there are hearings 10 days before scheduled" do
      subject { job.find_affected_hearings }
      it "find_affected_hearings returns relevant hearing" do
        subject
        expect(subject).not_to eq nil
        expect(subject).to eq appeal_list
        expect(subject[0]).to eq appeal_one
        expect(subject[1]).to eq appeal_two
      end
    end
    context "when there are ChangeHearingRequestTypeTasks to cancel" do
      subject { CancelChangeHearingRequestTypeTaskJob.disable_conversion_task(appeal_list) }
      schedule_day = current_time.next_day(10)

      let(:task) { create(:change_hearing_request_type_task, :assigned) }

      it "cancels the task" do
        byebug
        expect { subject }.to(
          change { task.reload.status }
            .from(Constants.TASK_STATUSES.assigned).to(Constants.TASK_STATUSES.cancelled)
        )
      end
    end
  end
end
