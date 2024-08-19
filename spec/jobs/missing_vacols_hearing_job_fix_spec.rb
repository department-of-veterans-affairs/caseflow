# frozen_string_literal: true

describe MissingVacolsHearingJobFix do
  let!(:hearing) { create(:legacy_hearing, :with_tasks) }
  let!(:hearing2) { create(:legacy_hearing, :with_tasks) }
  let!(:hearing3) { create(:legacy_hearing, :with_tasks) }
  let!(:hearing4) { create(:legacy_hearing, :with_tasks) }

  subject { described_class.new }

  context "missing_vacols_hearing" do
    context "when AssignHearingDispositionTask is outdated and the associated hearing doesn't exist in VACOLS" do
      it "cancels the task" do
        task = AssignHearingDispositionTask.find_by(appeal: hearing.appeal)
        task2 = AssignHearingDispositionTask.find_by(appeal: hearing2.appeal)
        task3 = AssignHearingDispositionTask.find_by(appeal: hearing3.appeal)
        task4 = AssignHearingDispositionTask.find_by(appeal: hearing4.appeal)
        task2.update(assigned_at: 3.years.ago)
        task3.update(assigned_at: 1.year.ago)
        task4.update(assigned_at: 2.years.ago)

        vacols_case2 = VACOLS::CaseHearing.find_by(hearing_pkseq: task2.hearing.vacols_id)
        vacols_case3 = VACOLS::CaseHearing.find_by(hearing_pkseq: task3.hearing.vacols_id)

        expect(task.status).to eq("assigned")
        expect(task2.status).to eq("assigned")
        expect(VACOLS::CaseHearing.count).to eq(4)
        vacols_case2.destroy!
        vacols_case3.destroy!

        expect(VACOLS::CaseHearing.count).to eq(2)
        subject.perform

        expect(VACOLS::CaseHearing.count).to eq(2)
        expect(task.reload.status).to eq("assigned")
        expect(task2.reload.status).to eq("cancelled")
        expect(task3.reload.status).to eq("cancelled")
        expect(task.hearing).to_not eq(nil)
        expect(task3.hearing).to_not eq(nil)
      end
    end
  end
end
