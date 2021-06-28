# frozen_string_literal: true

describe EvidenceSubmissionWindowTask, :postgres do
  let(:participant_id_with_pva) { "000000" }
  let(:participant_id_with_no_vso) { "11111" }
  let!(:receipt_date) { 2.days.ago }
  let(:docket_type) { Constants.AMA_DOCKETS.evidence_submission }
  let!(:appeal) do
    create(:appeal, docket_type: docket_type, receipt_date: receipt_date, claimants: [
             create(:claimant, participant_id: participant_id_with_pva)
           ])
  end
  let!(:appeal_no_vso) do
    create(:appeal, docket_type: docket_type, claimants: [
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
          participant_id: "2452383",
          file_number: "66660000"
        }
      )
    allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
      .with([participant_id_with_no_vso]).and_return({})
  end

  shared_examples "works for all remand subtypes" do
    context "if the appeal doesn't have a vso" do
      it "marks appeal as ready for distribution" do
        InitialTasksFactory.new(appeal_no_vso).create_root_and_sub_tasks!
        EvidenceSubmissionWindowTask.find_by(appeal: appeal_no_vso).update!(status: "completed")
        expect(DistributionTask.find_by(appeal: appeal_no_vso).status).to eq("assigned")
      end
    end
  end

  context "on complete" do
    it "creates an ihp task if the appeal has a vso" do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(0)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal).when_timer_ends
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(1)
      expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
    end

    context "appeal with no vso and hearing disposition is no_show" do
      let(:docket_type) { Constants.AMA_DOCKETS.hearing }
      let(:hearing) { create(:hearing, :no_show, :with_completed_tasks, appeal: appeal_no_vso) }

      let!(:task) do
        EvidenceSubmissionWindowTask.create!(
          appeal: appeal_no_vso,
          assigned_to: MailTeam.singleton,
          parent: HearingTaskAssociation.find_by(hearing_id: hearing.id).hearing_task
        )
      end

      subject { task.when_timer_ends }

      it "closes parent HearingTask and assigns grandparent DistributionTask" do
        subject
        task.reload

        expect(task.parent.status).to eq(Constants.TASK_STATUSES.completed)
        expect(task.parent.parent.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end

    include_examples "works for all remand subtypes"
  end

  context "on manual completion by user" do
    let(:mail_user) { create(:user) }
    let(:mail_team) { MailTeam.singleton }
    let(:instructions) { "here are the instructions" }
    let(:params) do
      {
        status: Constants.TASK_STATUSES.completed,
        instructions: [instructions]
      }
    end
    before do
      mail_team.add_user(mail_user)
    end
    it "creates an ihp task if appeal has vso" do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(0)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal).update_from_params(params, mail_user)
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(1)
      expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
    end

    include_examples "works for all remand subtypes"
  end

  context "timer_delay" do
    context "hearing is in the evidence submission docket" do
      before { InitialTasksFactory.new(appeal).create_root_and_sub_tasks! }

      let(:task) do
        appeal.tasks.last
      end

      it "is marked as complete and vso tasks are created in 90 days from receipt date" do
        TaskTimerJob.perform_now
        expect(task.reload.status).to eq("assigned")

        Timecop.travel(receipt_date + 90.days) do
          TaskTimerJob.perform_now
          expect(task.reload.status).to eq("completed")
        end
      end
    end

    context "appeal is in the hearing docket" do
      let(:root_task) { create(:root_task, appeal: appeal) }
      let(:hearing_task) { create(:hearing_task, parent: root_task) }
      let(:docket_type) { Constants.AMA_DOCKETS.hearing }

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

        it "sets the timer to end 90 days after the hearing day", :aggregate_failures do
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

      context "hearing is not in the evidences submission docket and the hearing request is withdrawn" do
        let!(:schedule_hearing_task) do
          create(
            :schedule_hearing_task,
            :cancelled,
            parent: hearing_task,
            appeal: appeal
          )
        end
        let!(:task) do
          EvidenceSubmissionWindowTask.create!(appeal: appeal, assigned_to: Bva.singleton, parent: hearing_task)
        end

        it "sets the timer to end 90 days after the hearing request is withdrawn" do
          TaskTimerJob.perform_now
          expect(task.reload.status).to eq("assigned")

          Timecop.travel(receipt_date + 90.days) do
            TaskTimerJob.perform_now
            expect(task.reload.status).to eq("assigned")
          end

          Timecop.travel(schedule_hearing_task.closed_at + 91.days) do
            TaskTimerJob.perform_now
            expect(task.reload.status).to eq("completed")
          end
        end
      end

      context "hearing is not in the evidences submission docket" \
              "and the hearing request is withdrawn with no schedule hearing task" do
        it "sends a message to Raven and sets the time to end 90 days after the task was created" do
          expect(Raven).to receive(:capture_message).once

          esw_task = EvidenceSubmissionWindowTask.create!(
            appeal: appeal,
            assigned_to: Bva.singleton,
            parent: hearing_task
          )

          task_timer = TaskTimer.find_by(task_id: esw_task.id)
          expect(task_timer.submitted_at).to be_within(10.seconds).of(esw_task.created_at + 90.days)
        end
      end
    end
  end
end
