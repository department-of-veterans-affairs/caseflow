# frozen_string_literal: true

describe OpenHearingTasksWithoutActiveDescendantsChecker, :all_dbs do
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
  let(:root_task) { create(:root_task, appeal: legacy_appeal) }
  let!(:hearing_task) do
    create(
      :hearing_task,
      appeal: legacy_appeal,
      parent: root_task
    )
  end
  let(:schedule_hearing_task) do
    create(
      :schedule_hearing_task,
      appeal: legacy_appeal,
      parent: hearing_task
    )
  end
  let(:org_verify_task) do
    create(
      :hearing_admin_action_verify_address_task,
      appeal: legacy_appeal,
      assigned_to: HearingsManagement.singleton,
      parent: schedule_hearing_task
    )
  end
  let(:user) { create(:user) }
  let!(:user_verify_task) do
    create(
      :hearing_admin_action_verify_address_task,
      appeal: legacy_appeal,
      assigned_to: user,
      parent: org_verify_task
    )
  end

  let(:appeal) { create(:appeal) }
  let(:root_task_2) { create(:root_task, appeal: appeal) }
  let(:hearing_task_2) { create(:hearing_task, parent: root_task_2) }
  let(:schedule_hearing_task_2) { create(:schedule_hearing_task, parent: hearing_task_2) }

  context "there are open hearing tasks without active descendants and without any descendants" do
    let(:appeal_2) { create(:appeal) }
    let(:root_task_3) { create(:root_task, appeal: appeal_2) }
    let!(:hearing_task_3) { create(:hearing_task, parent: root_task_3) }

    before do
      user_verify_task.update_columns(status: Constants.TASK_STATUSES.completed)
      org_verify_task.update_columns(status: Constants.TASK_STATUSES.completed)
      schedule_hearing_task_2.update_columns(status: Constants.TASK_STATUSES.completed)
    end

    describe "#call" do
      it "builds a report that includes the IDs of the open hearing tasks" do
        subject.call
        report_lines = subject.report.split("\n")
        ids = [hearing_task.id, hearing_task_2.id, hearing_task_3.id].sort
        expect(report_lines).to include("Found #{ids.count} open HearingTasks with no active descendant tasks.")
        expect(report_lines).to include("`HearingTask.where(id: #{ids})`")
      end
    end
  end

  context "there are no open hearing tasks without active descendants" do
    describe "#call" do
      it "does not build a report" do
        subject.call
        expect(subject.report?).to be_falsey
      end
    end
  end
end
