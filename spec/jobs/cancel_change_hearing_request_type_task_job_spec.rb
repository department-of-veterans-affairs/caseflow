# frozen_string_literal: true

describe CancelChangeHearingRequestTypeTaskJob do
  let(:job) { CancelChangeHearingRequestTypeTaskJob.new }
  current_time = Time.zone.today
  let(:appeal_one) { create(:appeal, id: 1) }
  let(:appeal_two) { create(:appeal, id: 2) }
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
      it "does not hit disable_conversion_task method" do
        # FIX ME how do u do that hting where u check if it reaches a method
        job.perform_now
      end
    end
  end
  describe "tasks that need to be cancelled" do
    subject { job.find_affected_hearings }

    schedule_day = current_time.next_day(10)
    let!(:hearing_day) { create(:hearing_day, scheduled_for: schedule_day) }
    let!(:hearing_one) { create(:hearing, hearing_day: hearing_day, appeal: appeal_one) }
    let!(:hearing_two) { create(:hearing, hearing_day: hearing_day, appeal: appeal_two) }
    let(:appeal_list) { [appeal_one, appeal_two] }
    let!(:root_task_one) { create(:root_task, appeal: appeal_one) }
    let!(:root_task_two) { create(:root_task, appeal: appeal_two) }

    let!(:vso_user) { create(:user, roles: ["VSO"], full_name: "test") }

    context "when there are hearings 10 days before scheduled" do
      it "find_affected_hearings returns relevant hearing" do
        subject
        expect(subject).not_to eq nil
        expect(subject).to eq appeal_list
        expect(subject[0]).to eq appeal_one
        expect(subject[1]).to eq appeal_two
      end
    end
    context "when there is one ChangeHearingRequestTypeTask to cancel" do
      let!(:task) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_one,
          appeal: root_task_one.appeal,
          assigned_to: vso_user
        )
      end

      it "cancels the task" do
        job.disable_conversion_task(appeal_list)
        expect(task.status).to eq "assigned"
        subject
        expect(task.reload.status).to eq "cancelled"
      end
    end

    context "when there are multiple tasks to cancel" do
      let!(:vso_one) { create(:user, roles: ["VSO"], full_name: "one") }
      let!(:vso_two) { create(:user, roles: ["VSO"], full_name: "two") }

      let!(:task_one) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_one,
          appeal: root_task_one.appeal,
          assigned_to: vso_one
        )
      end
      let!(:task_two) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_one,
          appeal: root_task_one.appeal,
          assigned_to: vso_two
        )
      end
      let!(:task_three) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_two,
          appeal: root_task_two.appeal,
          assigned_to: vso_one
        )
      end
      let!(:task_four) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_two,
          appeal: root_task_two.appeal,
          assigned_to: vso_two
        )
      end
      let!(:task_five) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_two,
          appeal: root_task_two.appeal,
          assigned_to: vso_one
        )
      end
      it "cancels all the tasks" do
        task_two.update!(status: "cancelled")
        task_three.update!(status: "cancelled")

        expect(task_one.status).to eq "assigned"
        expect(task_two.status).to eq "cancelled"
        expect(task_three.status).to eq "cancelled"
        expect(task_four.status).to eq "assigned"
        expect(task_five.status).to eq "assigned"

        job.disable_conversion_task(appeal_list)

        expect(task_one.reload.status).to eq "cancelled"
        expect(task_two.reload.status).to eq "cancelled"
        expect(task_three.reload.status).to eq "cancelled"
        expect(task_four.reload.status).to eq "cancelled"
        expect(task_five.reload.status).to eq "cancelled"
      end
    end

    context "when there are no tasks to cancel" do
      let!(:task) do
        create(
          :change_hearing_request_type_task,
          parent: root_task_one,
          appeal: root_task_one.appeal,
          assigned_to: vso_user
        )
      end
      it "everything stays the same" do
        task.update!(status: "cancelled")
        value = job.disable_conversion_task(appeal_list)
        expect(task.reload.status).to eq "cancelled"
        expect(value).to eq 0
      end
    end
  end
end
