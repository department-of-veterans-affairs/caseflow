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
    subject { schedule_hearing_task.update_from_params(update_params, hearings_management_user) }

    context "AMA appeal" do
      let(:hearing_day) do
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               regional_office: "RO18")
      end
      let(:schedule_hearing_task) { create(:schedule_hearing_task) }
      let(:update_params) do
        {
          status: Constants.TASK_STATUSES.completed,
          business_payloads: {
            description: "Update",
            values: {
              hearing_day_id: hearing_day.id,
              scheduled_time_string: "09:00"
            }
          }
        }
      end

      it "associates a caseflow hearing with the hearing day" do
        expect(subject.count).to eq(2)
        expect(Hearing.count).to eq(1)
        expect(Hearing.first.hearing_day).to eq(hearing_day)
        expect(Hearing.first.appeal).to eq(schedule_hearing_task.appeal)
      end

      it "creates a AssignHearingDispositionTask and associated object" do
        expect(subject.count).to eq(2)
        expect(AssignHearingDispositionTask.count).to eq(1)
        expect(AssignHearingDispositionTask.first.appeal).to eq(schedule_hearing_task.appeal)
        expect(HearingTaskAssociation.count).to eq(1)
        expect(HearingTaskAssociation.first.hearing).to eq(Hearing.first)
        expect(HearingTaskAssociation.first.hearing_task).to eq(HearingTask.first)
      end

      context "when params includes virtual_hearing_attributes" do
        let(:appellant_email) { "fake@email.com" }
        let(:virtual_hearing_attributes) do
          {
            appellant_email: appellant_email
          }
        end

        before do
          update_params[:business_payloads][:values][:virtual_hearing_attributes] = virtual_hearing_attributes
        end

        it "converts hearing to virtual hearing", :aggregate_failures do
          expect(subject.count).to eq(2)
          expect(Hearing.count).to eq(1)
          expect(Hearing.first.virtual_hearing).not_to eq(nil)
          expect(Hearing.first.virtual?).to eq(true)
          expect(Hearing.first.virtual_hearing.appellant_email).to eq(appellant_email)
        end

        context "with invalid params" do
          let(:appellant_email) { "blah" }

          it "raises error and does not create a hearing object" do
            expect { subject }
              .to raise_error(Caseflow::Error::VirtualHearingConversionFailed)
              .with_message("Validation failed: Appellant email does not appear to be a valid e-mail address")

            # does not create the hearing
            expect(Hearing.count).to eq(0)
            expect(AssignHearingDispositionTask.count).to eq(0)
          end
        end
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
        let(:veteran_pid) { "0000" }
        let(:schedule_hearing_task) do
          create(:schedule_hearing_task, appeal: appeal, assigned_to: hearings_management_user)
        end
        let(:representative_pid) { "1234" }

        before do
          allow(BGSService).to receive(:power_of_attorney_records).and_return(
            appeal.veteran_file_number => {
              file_number: appeal.veteran_file_number,
              ptcpnt_id: veteran_pid,
              power_of_attorney: {
                legacy_poa_cd: "3QQ",
                nm: "Clarence Darrow",
                org_type_nm: "POA Attorney",
                ptcpnt_id: representative_pid
              }
            }
          )
        end

        shared_examples "route to case storage location" do
          it "completes the task and updates the location to case storage" do
            expect(subject.count).to eq(1)
            expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.cancelled)
            expect(schedule_hearing_task.closed_at).to_not be_nil
            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:case_storage])
            expect(vacols_case.bfha).to eq("5")
            expect(vacols_case.bfhr).to eq("5")
          end
        end

        context "with no representatives" do
          include_examples "route to case storage location"
        end

        context "with non-VSO representative" do
          let!(:private_bar) { create(:private_bar, name: "test", participant_id: representative_pid) }

          include_examples "route to case storage location"

          it "has a representative" do
            expect(appeal.representatives.count).to eq 1
            expect(appeal.representatives.first).to eq private_bar
          end
        end

        context "with VSO" do
          let!(:vso) { create(:vso, name: "test", participant_id: representative_pid) }

          it "completes the task and updates the location to service organization" do
            expect(appeal.representatives.count).to eq 1
            expect(appeal.representatives.first).to eq vso

            expect(subject.count).to eq(1)

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
          expect(subject.count).to eq(2)
          expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(appeal.tasks.of_type(:EvidenceSubmissionWindowTask).count).to eq(1)
        end
      end
    end
  end

  describe "#create_change_hearing_disposition_task" do
    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:hearing_task) { create(:hearing_task, parent: root_task) }

    let!(:association) { create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
    let!(:hearing_task_2) { create(:hearing_task, parent: root_task) }
    let!(:task) { create(:schedule_hearing_task, parent: hearing_task_2) }
    let(:instructions) { "These are my detailed instructions for a schedule hearing task." }

    let!(:disposition_task) do
      create(:assign_hearing_disposition_task, parent: hearing_task)
    end

    subject { task.create_change_hearing_disposition_task(instructions) }

    before do
      [hearing_task, disposition_task].each { |task| task&.update!(status: Constants.TASK_STATUSES.completed) }
      create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
    end

    shared_examples "creates new task" do
      it "creates new hearing and change hearing disposition tasks and cancels unwanted tasks" do
        subject

        expect(hearing_task.reload.open?).to be_falsey
        expect(hearing_task.closed_at).to_not be_nil
        expect(disposition_task.reload.open?).to be_falsey
        expect(disposition_task.closed_at).to_not be_nil
        expect(hearing_task_2.reload.status).to eq Constants.TASK_STATUSES.cancelled
        expect(hearing_task_2.closed_at).to_not be_nil
        expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
        expect(task.cancelled_by).to eq hearings_management_user
        expect(task.closed_at).to_not be_nil
        new_hearing_tasks = appeal.tasks.open.of_type(:HearingTask)
        expect(new_hearing_tasks.count).to eq 1
        expect(new_hearing_tasks.first.hearing).to eq hearing
        new_change_tasks = appeal.tasks.open.of_type(:ChangeHearingDispositionTask)
        expect(new_change_tasks.count).to eq 1
        expect(new_change_tasks.first.parent).to eq new_hearing_tasks.first
      end
    end

    context "AMA appeal" do
      let(:appeal) { create(:appeal) }
      let(:past_hearing_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
      let(:hearing) { create(:hearing, appeal: appeal, disposition: past_hearing_disposition) }

      include_examples "creates new task"

      it "does not create ihp tasks" do
        subject

        expect(InformalHearingPresentationTask.where(appeal_id: appeal.id).count).to eq(0)
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

      context "there's another open task on the hearing task" do
        let!(:extra_task) { create(:assign_hearing_disposition_task, parent: hearing_task_2) }

        it "sends an exception to Raven and raises a RecordInvalid error" do
          # tells Raven why we couldn't close the HearingTask
          expect(Raven).to receive(:capture_exception)
          # errors when we try to create a new HearingTaskAssociation on
          # the same hearing as the still-open HearingTask
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "Legacy Appeal" do
      let(:vacols_case) { create(:case, bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow]) }
      let(:veteran_pid) { "0000" }
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let(:case_hearing_past_disposition) { VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:postponed] }
      let(:hearing) { create(:legacy_hearing, appeal: appeal, disposition: case_hearing_past_disposition) }

      include_examples "creates new task"

      it "does not change location" do
        subject

        expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:caseflow])
      end
    end
  end
end
