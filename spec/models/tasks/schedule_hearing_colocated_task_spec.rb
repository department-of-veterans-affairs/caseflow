# frozen_string_literal: true

describe ScheduleHearingColocatedTask, :all_dbs do
  describe ".completed!" do
    let(:appeal) { create(:appeal, :at_attorney_drafting) }
    let(:parent) { AttorneyTask.find_by(appeal: appeal) }
    let!(:schedule_hearing_colocated_task) do
      create(:colocated_task, :schedule_hearing, appeal: appeal, parent: parent)
    end

    let(:distributed_case) do
      DistributedCase.create!(
        distribution: create(:distribution, judge: JudgeTask.find_by(appeal: appeal).assigned_to),
        ready_at: Time.zone.now,
        docket: appeal.docket_type,
        priority: false,
        case_id: appeal.uuid,
        task: DistributionTask.find_by(appeal: appeal)
      )
    end

    subject { schedule_hearing_colocated_task.completed! }

    it "should send the appeal back to the hearings branch" do
      expect(DistributionTask.where(appeal: appeal).count).to eq 1
      expect(HearingTask.where(appeal: appeal).count).to eq 0
      expect(ScheduleHearingTask.where(appeal: appeal).count).to eq 0
      expect(DistributionTask.where(appeal: appeal).count).to eq 1
      expect(JudgeDecisionReviewTask.find_by(appeal: appeal).status).to eq Task.statuses[:on_hold]
      expect(AttorneyTask.find_by(appeal: appeal).status).to eq Task.statuses[:on_hold]
      expect(ScheduleHearingColocatedTask.find_by(appeal: appeal).status).to eq Task.statuses[:assigned]
      expect(distributed_case.case_id).to eq appeal.uuid

      subject

      expect(DistributionTask.where(appeal: appeal).count).to eq 2
      expect(HearingTask.where(appeal: appeal).count).to eq 1
      expect(ScheduleHearingTask.where(appeal: appeal).count).to eq 1
      expect(JudgeDecisionReviewTask.find_by(appeal: appeal).status).to eq Task.statuses[:cancelled]
      expect(AttorneyTask.find_by(appeal: appeal).status).to eq Task.statuses[:cancelled]
      expect(ScheduleHearingColocatedTask.find_by(appeal: appeal).status).to eq Task.statuses[:completed]
      expect(distributed_case.reload.case_id).to match /#{appeal.uuid}-redistributed-.*/
    end
  end
end
