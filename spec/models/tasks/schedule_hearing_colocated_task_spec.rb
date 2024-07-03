# frozen_string_literal: true

describe ScheduleHearingColocatedTask, :all_dbs do
  describe ".completed!" do
    before { create(:case_distribution_lever, :request_more_cases_minimum) }

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
        task: DistributionTask.find_by(appeal: appeal),
        sct_appeal: false
      )
    end
    subject { schedule_hearing_colocated_task.completed! }

    it "should send the appeal back to the hearings branch" do
      expect(HearingTask.where(appeal: appeal).count).to eq 0
      expect(DistributionTask.where(appeal: appeal).count).to eq 1
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
      expect(distributed_case.reload.case_id).to match(/#{appeal.uuid}-redistributed-.*/)
    end
  end
  describe "Completing a ScheduleHearingColocatedTask" do
    context "When ScheduleHearingColocatedTask has a parent AttorneyQualityReviewTask" do
      let(:appeal) { create(:appeal, :at_attorney_drafting) }
      let(:root_task) { RootTask.find_by(appeal: appeal) }

      let(:judge) { create(:user) }
      let(:atty) { create(:user) }
      let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }
      let!(:atty_staff) { create(:staff, :attorney_role, sdomainid: atty.css_id) }
      let!(:qr_user) { create(:user) }
      let!(:qr_relationship) { QualityReview.singleton.add_user(qr_user) }
      let!(:qr_org_task) { QualityReviewTask.create_from_root_task(root_task) }
      let!(:qr_person_task_params) do
        [{
          appeal: appeal,
          parent_id: qr_org_task.id,
          assigned_to_id: qr_user.id,
          assigned_to_type: qr_user.class.name,
          assigned_by: qr_user
        }]
      end
      let!(:qr_person_task) { QualityReviewTask.create_many_from_params(qr_person_task_params, qr_user).first }

      let(:judge_task_params) do
        {
          assigned_to_id: judge.id,
          assigned_to_type: User.name,
          appeal: qr_person_task.appeal,
          parent_id: qr_person_task.id
        }
      end
      let(:judge_qr_task) { JudgeQualityReviewTask.create_from_params(judge_task_params, qr_user) }

      let(:atty_task_params) do
        {
          assigned_to_id: atty.id,
          assigned_to_type: User.name,
          appeal: qr_person_task.appeal,
          parent_id: judge_qr_task.id
        }
      end
      let(:atty_qr_task) { AttorneyQualityReviewTask.create_from_params(atty_task_params, judge) }

      let!(:schedule_hearing_colocated_task) do
        create(:colocated_task, :schedule_hearing, appeal: appeal, parent: atty_qr_task)
      end

      subject { schedule_hearing_colocated_task.completed! }

      it "Should not cancel the JudgeQualityReviewTask and descendants" do
        expect(qr_org_task.reload.status).to eq Task.statuses[:on_hold]
        expect(qr_person_task.reload.status).to eq Task.statuses[:on_hold]
        expect(JudgeQualityReviewTask.find_by(appeal: appeal).status).to eq Task.statuses[:on_hold]
        expect(AttorneyQualityReviewTask.find_by(appeal: appeal).status).to eq Task.statuses[:on_hold]
        expect(ScheduleHearingColocatedTask.find_by(appeal: appeal).status).to eq Task.statuses[:assigned]
        subject
        expect(qr_org_task.reload.status).to eq Task.statuses[:on_hold]
        expect(qr_person_task.reload.status).to eq Task.statuses[:on_hold]
        expect(JudgeQualityReviewTask.find_by(appeal: appeal).status).to eq Task.statuses[:on_hold]
        expect(AttorneyQualityReviewTask.find_by(appeal: appeal).status).to eq Task.statuses[:assigned]
        expect(ScheduleHearingColocatedTask.find_by(appeal: appeal).status).to eq Task.statuses[:completed]
      end
    end
  end
end
