# frozen_string_literal: true

describe EvidenceSubmissionWindowTask, :postgres do
  let(:participant_id_with_pva) { "000000" }
  let(:participant_id_with_no_vso) { "11111" }
  let!(:receipt_date) { 2.days.ago }
  let!(:appeal) do
    create(:appeal, docket_type: Constants.AMA_DOCKETS.evidence_submission, receipt_date: receipt_date, claimants: [
             create(:claimant, participant_id: participant_id_with_pva)
           ])
  end
  let!(:appeal_no_vso) do
    create(:appeal, docket_type: Constants.AMA_DOCKETS.evidence_submission, claimants: [
             create(:claimant, participant_id: participant_id_with_no_vso)
           ])
  end

  before do
    Vso.create(
      name: "Paralyzed Veterans Of America",
      role: "VSO",
      url: "paralyzed-veterans-of-america",
      participant_id: "2452383"
    )

    allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
      .with([participant_id_with_pva]).and_return(
        participant_id_with_pva => {
          representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
          representative_type: "POA National Organization",
          participant_id: "2452383"
        }
      )
    allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
      .with([participant_id_with_no_vso]).and_return({})
  end

  context "on complete" do
    it "creates an ihp task if the appeal has a vso" do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(0)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal).when_timer_ends
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(1)
      expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
    end

    it "marks appeal as ready for distribution if the appeal doesn't have a vso" do
      InitialTasksFactory.new(appeal_no_vso).create_root_and_sub_tasks!
      EvidenceSubmissionWindowTask.find_by(appeal: appeal_no_vso).update!(status: "completed")
      expect(DistributionTask.find_by(appeal: appeal_no_vso).status).to eq("assigned")
    end
  end

  context "timer_delay" do
    context "parent is not a AssignHearingDispositionTask" do
      before { InitialTasksFactory.new(appeal).create_root_and_sub_tasks! }

      let(:task) do
        appeal.tasks.last
      end

      it "is marked as complete and vso tasks are created in 90 days" do
        TaskTimerJob.perform_now
        expect(task.reload.status).to eq("assigned")

        Timecop.travel(receipt_date + 90.days) do
          TaskTimerJob.perform_now
          expect(task.reload.status).to eq("completed")
        end
      end
    end

    context "parent is a AssignHearingDispositionTask and there is a held hearing" do
      let(:root_task) { create(:root_task, appeal: appeal) }
      let(:hearing_task) { create(:hearing_task, parent: root_task) }
      let(:hearing_day) { create(:hearing_day, scheduled_for: appeal.receipt_date + 15.days) }
      let(:hearing) do
        create(
          :hearing,
          appeal: appeal,
          disposition: Constants.HEARING_DISPOSITION_TYPES.held,
          hearing_day: hearing_day
        )
      end
      let!(:hearing_task_association) do
        create(
          :hearing_task_association,
          hearing: hearing,
          hearing_task: hearing_task
        )
      end
      let!(:parent) do
        create(
          :assign_hearing_disposition_task,
          :in_progress,
          parent: hearing_task
        )
      end
      let!(:task) do
        EvidenceSubmissionWindowTask.create!(appeal: appeal, assigned_to: Bva.singleton, parent: parent)
      end

      it "sets the timer to end 90 days after the hearing day" do
        TaskTimerJob.perform_now
        expect(task.reload.status).to eq("assigned")

        Timecop.travel(receipt_date + 90.days) do
          TaskTimerJob.perform_now
          expect(task.reload.status).to eq("assigned")
        end

        Timecop.travel(hearing_day.scheduled_for + 90.days) do
          TaskTimerJob.perform_now
          expect(task.reload.status).to eq("completed")
        end
      end
    end
  end
end
