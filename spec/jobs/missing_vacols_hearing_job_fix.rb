# frozen_string_literal: true

describe MissingVacolsHearingJobFix do
  subject { MissingVacolsHearingJobFix.new }
  let!(:hearing) { create(:legacy_hearing, :with_tasks) }
  let!(:hearing2) { create(:legacy_hearing, :with_tasks) }
  let!(:hearing3) { create(:legacy_hearing, :with_tasks) }

  context "missing_vacols_hearing" do
    context "when AssignHearingDispositionTask is outdated and the associated hearing doesn't exist in VACOLS" do
      it "cancels the task" do
        task = AssignHearingDispositionTask.find_by(appeal: hearing.appeal)
        task2 = AssignHearingDispositionTask.find_by(appeal: hearing2.appeal)
        task3 = AssignHearingDispositionTask.find_by(appeal: hearing3.appeal)

        vacols_case2 = VACOLS::CaseHearing.find_by(hearing_pkseq: task2.hearing.vacols_id)
        vacols_case3 = VACOLS::CaseHearing.find_by(hearing_pkseq: task3.hearing.vacols_id)

        task2.update(assigned_at: 3.years.ago)
        task3.update(assigned_at: 1.year.ago)

        expect(task.status).to eq("assigned")
        expect(task2.status).to eq("assigned")
        expect(VACOLS::CaseHearing.count).to eq(3)
        vacols_case2.destroy!
        vacols_case3.destroy!

        expect(VACOLS::CaseHearing.count).to eq(1)
        subject.perform

        expect(VACOLS::CaseHearing.count).to eq(1)
        expect(task.reload.status).to eq("assigned")
        expect(task2.reload.status).to eq("cancelled")
        expect(task3.reload.status).to eq("cancelled")
        expect(task.hearing).to_not eq(nil)
        expect(task3.hearing).to_not eq(nil)
      end
    end
    context "when one of the AssignHearingDispositionTasks does not have an associated hearing" do
      it "continues with the rest of the tasks and logs the error" do
        allow(Rails.logger).to receive(:error)
        task2 = AssignHearingDispositionTask.find_by(appeal: hearing2.appeal)
        task3 = AssignHearingDispositionTask.find_by(appeal: hearing3.appeal)
        vacols_case2 = VACOLS::CaseHearing.find_by(hearing_pkseq: task2.hearing.vacols_id)
        vacols_case3 = VACOLS::CaseHearing.find_by(hearing_pkseq: task3.hearing.vacols_id)
        task2.update(assigned_at: 3.years.ago)
        task3.update(assigned_at: 1.year.ago)
        string = "ALERT------- Task Id's: #{task2.id} are missing associated "\
                 "hearings. This requires manual remediation------- ALERT"
        vacols_case2.destroy
        vacols_case3.destroy
        task2.hearing.destroy
        expect(task2.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(task3.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(task3.status).to eq(Constants.TASK_STATUSES.assigned)
        Rails.logger.should_receive(:error).with(string)
        subject.perform
        expect(task3.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(task2.reload.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end
    context "when one of the qualifying tasks is outside of the assigned_at parameters " do
      it "should not process tasks that have an 'assigned_at' of over 7 years or before 5 months" do
        task2 = AssignHearingDispositionTask.find_by(appeal: hearing2.appeal)
        task3 = AssignHearingDispositionTask.find_by(appeal: hearing3.appeal)
        vacols_case2 = VACOLS::CaseHearing.find_by(hearing_pkseq: task2.hearing.vacols_id)
        vacols_case3 = VACOLS::CaseHearing.find_by(hearing_pkseq: task3.hearing.vacols_id)

        task2.update(assigned_at: 3.months.ago)
        task3.update(assigned_at: 8.years.ago)
        vacols_case2.destroy
        vacols_case3.destroy

        expect(task2.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(task3.status).to eq(Constants.TASK_STATUSES.assigned)
        subject.perform
        expect(task2.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(task3.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end
    context "when there are no qualifying AssignHearingDispositionTasks" do
      it "should not fail/ return a successful message" do
        expect(subject.perform).to be_truthy
      end
    end
  end
end
