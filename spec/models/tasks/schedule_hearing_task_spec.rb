# frozen_string_literal: true

describe ScheduleHearingTask, :all_dbs do
  let(:vacols_case) { create(:case, bfcurloc: "57") }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let!(:hearings_management_user) { create(:hearings_coordinator) }
  let(:test_hearing_date_vacols) do
    Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.local(2018, 11, 2, 6, 0, 0)
    end
  end

  before do
    Time.zone = "Eastern Time (US & Canada)"
    HearingsManagement.singleton.add_user(hearings_management_user)
    RequestStore[:current_user] = hearings_management_user
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context "create a new ScheduleHearingTask" do
    let(:appeal) { create(:appeal, :hearing_docket) }

    subject do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end

    it "is assigned to the Bva org by default" do
      expect(ScheduleHearingTask.count).to eq 0

      subject

      expect(ScheduleHearingTask.count).to eq 1
      task = ScheduleHearingTask.first

      expect(task.assigned_to_type).to eq "Organization"
      expect(task.assigned_to).to eq Bva.singleton
    end

    it "has actions available to the hearings managment org member" do
      subject

      task = ScheduleHearingTask.first
      expect(task.available_actions_unwrapper(hearings_management_user).count).to be > 0
    end

    context "there is a hearing admin org user" do
      let(:hearing_admin_user) { create(:user, station_id: 101) }

      before do
        HearingAdmin.singleton.add_user(hearing_admin_user)
      end

      it "has no actions available to the hearing admin org member" do
        subject

        task = ScheduleHearingTask.first
        expect(task.available_actions_unwrapper(hearing_admin_user).count).to eq 0
      end
    end
  end

  context "create a ScheduleHearingTask with parent other than HearingTask type" do
    let(:root_task) { create(:root_task, appeal: appeal) }

    subject { create(:schedule_hearing_task, parent: root_task) }

    it "creates a HearingTask in between the input parent and the ScheduleHearingTask" do
      expect { subject }.to_not raise_error
      expect(subject.parent).to be_a(HearingTask)
      expect(subject.parent.parent).to eq(root_task)
    end
  end

  describe "#update_from_params" do
    context "AMA appeal" do
      let(:hearing_day) do
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               regional_office: "RO18")
      end
      let(:schedule_hearing_task) { create(:schedule_hearing_task) }
      let(:update_params) do
        {
          status: "completed",
          business_payloads: {
            description: "Update",
            values: {
              "hearing_day_id": hearing_day.id,
              "scheduled_time_string": "09:00"
            }
          }
        }
      end

      it "associates a caseflow hearing with the hearing day" do
        schedule_hearing_task.update_from_params(update_params, hearings_management_user)

        expect(Hearing.count).to eq(1)
        expect(Hearing.first.hearing_day).to eq(hearing_day)
        expect(Hearing.first.appeal).to eq(schedule_hearing_task.appeal)
      end

      it "creates a AssignHearingDispositionTask and associated object" do
        schedule_hearing_task.update_from_params(update_params, hearings_management_user)

        expect(AssignHearingDispositionTask.count).to eq(1)
        expect(AssignHearingDispositionTask.first.appeal).to eq(schedule_hearing_task.appeal)
        expect(HearingTaskAssociation.count).to eq(1)
        expect(HearingTaskAssociation.first.hearing).to eq(Hearing.first)
        expect(HearingTaskAssociation.first.hearing_task).to eq(HearingTask.first)
      end
    end

    context "when cancelled" do
      let(:update_params) do
        {
          status: Constants.TASK_STATUSES.cancelled
        }
      end

      context "for legacy appeal" do
        let(:vacols_case) { create(:case) }
        let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
        let(:veteran_participant_id) { "0000" }
        let(:schedule_hearing_task) do
          create(:schedule_hearing_task, appeal: appeal, assigned_to: hearings_management_user)
        end

        context "with no VSO" do
          it "completes the task and updates the location to case storage" do
            schedule_hearing_task.update_from_params(update_params, hearings_management_user)

            expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.cancelled)
            expect(schedule_hearing_task.closed_at).to_not be_nil
            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:case_storage])
            expect(vacols_case.bfha).to eq("5")
            expect(vacols_case.bfhr).to eq("5")
          end
        end

        context "with VSO" do
          let(:participant_id) { "1234" }
          let!(:vso) { create(:vso, name: "test", participant_id: participant_id) }

          before do
            allow(BGSService).to receive(:power_of_attorney_records).and_return(
              appeal.veteran_file_number => {
                file_number: appeal.veteran_file_number,
                ptcpnt_id: veteran_participant_id,
                power_of_attorney: {
                  legacy_poa_cd: "3QQ",
                  nm: "Clarence Darrow",
                  org_type_nm: "POA Attorney",
                  ptcpnt_id: participant_id
                }
              }
            )
          end

          it "completes the task and updates the location to service organization" do
            schedule_hearing_task.update_from_params(update_params, hearings_management_user)

            expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.cancelled)
            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:service_organization])
            expect(vacols_case.bfha).to eq("5")
            expect(vacols_case.bfhr).to eq("5")
          end
        end
      end

      context "AMA appeal" do
        let(:appeal) { create(:appeal) }
        let(:schedule_hearing_task) do
          create(:schedule_hearing_task, appeal: appeal, assigned_to: hearings_management_user)
        end

        it "completes the task and creates an EvidenceSubmissionWindowTask" do
          schedule_hearing_task.update_from_params(update_params, hearings_management_user)

          expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(appeal.tasks.where(type: EvidenceSubmissionWindowTask.name).count).to eq(1)
        end
      end
    end
  end

  describe "#create_change_hearing_disposition_task" do
    let(:appeal) { create(:appeal) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:past_hearing_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
    let(:hearing) { create(:hearing, appeal: appeal, disposition: past_hearing_disposition) }
    let(:hearing_task) { create(:hearing_task, parent: root_task) }
    let!(:disposition_task) do
      create(:assign_hearing_disposition_task, parent: hearing_task)
    end
    let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
    let!(:hearing_task_2) { create(:hearing_task, parent: root_task) }
    let!(:task) { create(:schedule_hearing_task, parent: hearing_task_2) }
    let(:instructions) { "These are my detailed instructions for a schedule hearing task." }

    before do
      [hearing_task, disposition_task].each { |task| task&.update!(status: Constants.TASK_STATUSES.completed) }
      create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
    end

    subject { task.create_change_hearing_disposition_task(instructions) }

    it "creates new hearing and change hearing disposition tasks and cancels unwanted tasks" do
      subject

      expect(hearing_task.reload.open?).to be_falsey
      expect(hearing_task.closed_at).to_not be_nil
      expect(disposition_task.reload.open?).to be_falsey
      expect(disposition_task.closed_at).to_not be_nil
      expect(hearing_task_2.reload.status).to eq Constants.TASK_STATUSES.cancelled
      expect(hearing_task_2.closed_at).to_not be_nil
      expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      expect(task.closed_at).to_not be_nil
      new_hearing_tasks = appeal.tasks.open.where(type: HearingTask.name)
      expect(new_hearing_tasks.count).to eq 1
      expect(new_hearing_tasks.first.hearing).to eq hearing
      new_change_tasks = appeal.tasks.open.where(type: ChangeHearingDispositionTask.name)
      expect(new_change_tasks.count).to eq 1
      expect(new_change_tasks.first.parent).to eq new_hearing_tasks.first
    end

    context "the past hearing disposition is nil" do
      let(:past_hearing_disposition) { nil }

      it "raises an error" do
        expect { subject }
          .to raise_error(Caseflow::Error::ActionForbiddenError)
          .with_message(COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR)
      end
    end

    context "there's no past inactive hearing task" do
      let(:hearing_task) { nil }
      let(:disposition_task) { nil }
      let(:association) { nil }

      it "raises an error" do
        expect { subject }
          .to raise_error(Caseflow::Error::ActionForbiddenError)
          .with_message(COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR)
      end
    end
  end
end
