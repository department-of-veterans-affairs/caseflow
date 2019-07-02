# frozen_string_literal: true

describe ScheduleHearingTask do
  let(:vacols_case) { FactoryBot.create(:case, bfcurloc: "57") }
  let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: vacols_case) }
  let!(:hearings_management_user) { FactoryBot.create(:hearings_coordinator) }
  let(:test_hearing_date_vacols) do
    Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.local(2018, 11, 2, 6, 0, 0)
    end
  end

  before do
    Time.zone = "Eastern Time (US & Canada)"
    OrganizationsUser.add_user_to_organization(hearings_management_user, HearingsManagement.singleton)
    RequestStore[:current_user] = hearings_management_user
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context "create a new ScheduleHearingTask" do
    let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }

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
      let(:hearing_admin_user) { FactoryBot.create(:user, station_id: 101) }

      before do
        OrganizationsUser.add_user_to_organization(hearing_admin_user, HearingAdmin.singleton)
      end

      it "has no actions available to the hearing admin org member" do
        subject

        task = ScheduleHearingTask.first
        expect(task.available_actions_unwrapper(hearing_admin_user).count).to eq 0
      end
    end
  end

  context "create a ScheduleHearingTask with parent other than HearingTask type" do
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }

    subject { FactoryBot.create(:schedule_hearing_task, parent: root_task) }

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
        let(:schedule_hearing_task) do
          create(:schedule_hearing_task, appeal: appeal, assigned_to: hearings_management_user)
        end

        context "with no VSO" do
          it "completes the task and updates the location to case storage" do
            schedule_hearing_task.update_from_params(update_params, hearings_management_user)

            expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.cancelled)
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
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:past_hearing_disposition) { Constants.HEARING_DISPOSITION_TYPES.postponed }
    let(:hearing) { FactoryBot.create(:hearing, appeal: appeal, disposition: past_hearing_disposition) }
    let(:hearing_task) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:disposition_task) { FactoryBot.create(:assign_hearing_disposition_task, parent: hearing_task, appeal: appeal) }
    let!(:association) { FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task) }
    let!(:hearing_task_2) { FactoryBot.create(:hearing_task, parent: root_task, appeal: appeal) }
    let!(:task) { FactoryBot.create(:schedule_hearing_task, parent: hearing_task_2, appeal: appeal) }
    let(:instructions) { "These are my detailed instructions for a schedule hearing task." }

    before do
      [hearing_task, disposition_task].each { |task| task&.update!(status: Constants.TASK_STATUSES.completed) }
      FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: hearing_task_2)
    end

    subject { task.create_change_hearing_disposition_task(instructions) }

    it "creates new hearing and change hearing disposition tasks and cancels unwanted tasks" do
      subject

      expect(hearing_task.reload.open?).to be_falsey
      expect(disposition_task.reload.open?).to be_falsey
      expect(hearing_task_2.reload.status).to eq Constants.TASK_STATUSES.cancelled
      expect(task.reload.status).to eq Constants.TASK_STATUSES.cancelled
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

  describe "#tasks_for_ro" do
    let(:regional_office) { "RO17" }
    let(:number_of_cases) { 10 }

    context "when there are no cases CO hearings" do
      let!(:cases) do
        create_list(:case, number_of_cases,
                    bfregoff: regional_office,
                    bfhr: "2",
                    bfcurloc: "57",
                    bfdocind: HearingDay::REQUEST_TYPES[:video])
      end

      let!(:c_number_case) do
        create(
          :case,
          bfcorlid: "1234C",
          bfregoff: regional_office,
          bfhr: "2",
          bfcurloc: 57,
          bfdocind: HearingDay::REQUEST_TYPES[:video]
        )
      end

      let!(:veterans) do
        VACOLS::Case.all.map do |vacols_case|
          create(
            :veteran,
            file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
          )
        end
      end

      let!(:non_hearing_cases) do
        create_list(:case, number_of_cases)
      end

      before do
        AppealRepository.create_schedule_hearing_tasks.each do |appeal|
          appeal.update(closest_regional_office: regional_office)
        end
      end

      it "returns tasks for all relevant appeals in location 57" do
        tasks = ScheduleHearingTask.tasks_for_ro(regional_office)

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey) + [c_number_case.bfkey])
      end
    end

    context "when there are cases with central office hearings" do
      let!(:cases) do
        create_list(:case, number_of_cases,
                    bfregoff: regional_office,
                    bfhr: "1",
                    bfcurloc: "57",
                    bfdocind: HearingDay::REQUEST_TYPES[:central])
      end

      let!(:video_cases) do
        create_list(:case, number_of_cases,
                    bfregoff: regional_office,
                    bfhr: "2",
                    bfcurloc: "57",
                    bfdocind: HearingDay::REQUEST_TYPES[:video])
      end

      let!(:veterans) do
        VACOLS::Case.all.map do |vacols_case|
          create(
            :veteran,
            file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
          )
        end
      end

      before do
        AppealRepository.create_schedule_hearing_tasks.each do |appeal|
          appeal.update(closest_regional_office: regional_office)
        end
      end

      it "returns tasks for all CO hearings in location 57" do
        tasks = ScheduleHearingTask.tasks_for_ro("C")

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey))
      end

      it "does not return tasks for regional office when marked as CO" do
        AppealRepository.create_schedule_hearing_tasks

        tasks = ScheduleHearingTask.tasks_for_ro(regional_office)

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(video_cases.pluck(:bfkey))
      end
    end

    context "when there are AMA ScheduleHearingTasks" do
      let(:veteran_at_ro) { create(:veteran) }
      let(:appeal_for_veteran_at_ro) do
        create(:appeal, veteran: veteran_at_ro, closest_regional_office: regional_office)
      end
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal_for_veteran_at_ro) }

      let(:veteran_at_different_ro) { create(:veteran) }
      let(:appeal_for_veteran_at_different_ro) do
        create(:appeal, veteran: veteran_at_different_ro, closest_regional_office: "RO04")
      end
      let!(:hearing_task_for_other_veteran) do
        create(:schedule_hearing_task, appeal: appeal_for_veteran_at_different_ro)
      end

      it "returns tasks for all appeals associated with Veterans at regional office" do
        tasks = ScheduleHearingTask.tasks_for_ro(regional_office)

        expect(tasks.count).to eq(1)
        expect(tasks[0].id).to eq(schedule_hearing_task.id)
      end
    end
  end
end
