describe ScheduleHearingTask do
  before do
    Time.zone = "Eastern Time (US & Canada)"
    OrganizationsUser.add_user_to_organization(hearings_user, HearingsManagement.singleton)
    RequestStore[:current_user] = hearings_user
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:vacols_case) { FactoryBot.create(:case, bfcurloc: "57") }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let!(:hearings_user) { create(:hearings_coordinator) }
  let(:staff) { create(:staff, sdomainid: "BVATWARNER", slogid: "TWARNER") }
  let!(:hearings_org) { create(:hearings_management) }

  let(:test_hearing_date_vacols) do
    Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.local(2018, 11, 2, 6, 0, 0)
    end
  end

  describe "Add a schedule hearing task" do
    let(:root_task) { FactoryBot.create(:root_task, appeal_type: root_task_appeal_type, appeal: appeal) }
    let(:root_task_appeal_type) { LegacyAppeal.name }
    let(:params) do
      {
        type: ScheduleHearingTask.name,
        action: "Assign Hearing",
        appeal: appeal,
        assigned_to_type: "User",
        assigned_to_id: hearings_user.id,
        parent_id: root_task.id
      }
    end

    subject { ScheduleHearingTask.find_or_create_if_eligible(appeal) }

    it "should create a task of type ScheduleHearingTask" do
      expect(subject.type).to eq(ScheduleHearingTask.name)
      expect(subject.appeal_type).to eq(LegacyAppeal.name)
      expect(subject.status).to eq("assigned")
    end
  end

  context "#update_from_params" do
    context "AMA appeal" do
      let(:hearing_day) { create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video]) }
      let(:appeal) { create(:appeal) }
      let(:schedule_hearing_task) do
        ScheduleHearingTask.create!(appeal: appeal, assigned_to: hearings_user)
      end
      let(:update_params) do
        {
          status: "completed",
          business_payloads: {
            description: "Update",
            values: {
              "regional_office_value": hearing_day.regional_office,
              "hearing_pkseq": hearing_day.id,
              "hearing_time": {
                "h": "09",
                "m": "00",
                "offset": "-0500"
              },
              "hearing_type": "Video"
            }
          }
        }
      end

      it "associates a caseflow hearing with the hearing day" do
        schedule_hearing_task.update_from_params(update_params, hearings_user)

        expect(Hearing.count).to eq(1)
        expect(Hearing.first.hearing_day).to eq(hearing_day)
        expect(Hearing.first.appeal).to eq(appeal)
      end

      it "creates a HoldHearingTask" do
        schedule_hearing_task.update_from_params(update_params, hearings_user)

        expect(HoldHearingTask.count).to eq(1)
        expect(HoldHearingTask.first.appeal).to eq(appeal)
      end
    end

    context "when canceled" do
      let(:update_params) do
        {
          status: "canceled"
        }
      end

      context "for legacy appeal" do
        let(:vacols_case) { create(:case) }
        let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
        let(:schedule_hearing_task) do
          ScheduleHearingTask.create!(appeal: appeal, assigned_to: hearings_user)
        end

        context "with no VSO" do
          it "completes the task and updates the location to case storage" do
            schedule_hearing_task.update_from_params(update_params, hearings_user)

            expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)
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
            schedule_hearing_task.update_from_params(update_params, hearings_user)

            expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)
            expect(vacols_case.reload.bfcurloc).to eq(LegacyAppeal::LOCATION_CODES[:service_organization])
            expect(vacols_case.bfha).to eq("5")
            expect(vacols_case.bfhr).to eq("5")
          end
        end
      end

      context "AMA appeal" do
        let(:appeal) { create(:appeal) }
        let(:schedule_hearing_task) do
          ScheduleHearingTask.create!(appeal: appeal, assigned_to: hearings_user)
        end

        it "completes the task and creates an EvidenceSubmissionWindowTask" do
          schedule_hearing_task.update_from_params(update_params, hearings_user)

          expect(schedule_hearing_task.status).to eq(Constants.TASK_STATUSES.completed)
          expect(appeal.tasks.where(type: EvidenceSubmissionWindowTask.name).count).to eq(1)
        end
      end
    end
  end

  context ".legacy_tasks_for_ro" do
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
            closest_regional_office: regional_office,
            file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
          )
        end
      end

      let!(:non_hearing_cases) do
        create_list(:case, number_of_cases)
      end

      it "returns tasks for all relevant appeals in location 57" do
        AppealRepository.create_schedule_hearing_tasks

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
            closest_regional_office: regional_office,
            file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
          )
        end
      end

      it "returns tasks for all CO hearings in location 57" do
        AppealRepository.create_schedule_hearing_tasks

        tasks = ScheduleHearingTask.tasks_for_ro("C")

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey))
      end

      it "does not return tasks for regional office when marked as CO" do
        AppealRepository.create_schedule_hearing_tasks

        tasks = ScheduleHearingTask.tasks_for_ro(regional_office)

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(video_cases.pluck(:bfkey))
      end
    end
  end

  context ".tasks_for_ro" do
    let(:regional_office) { "RO17" }

    context "when there are AMA ScheduleHearingTasks" do
      let(:veteran_at_ro) { create(:veteran, closest_regional_office: regional_office) }
      let(:appeal_for_veteran_at_ro) { create(:appeal, veteran: veteran_at_ro) }
      let!(:hearing_task) { create(:schedule_hearing_task, appeal: appeal_for_veteran_at_ro) }

      let(:veteran_at_different_ro) { create(:veteran, closest_regional_office: "RO04") }
      let(:appeal_for_veteran_at_different_ro) { create(:appeal, veteran: veteran_at_different_ro) }
      let!(:hearing_task_for_other_veteran) do
        create(:schedule_hearing_task, appeal: appeal_for_veteran_at_different_ro)
      end

      it "returns tasks for all appeals associated with Veterans at regional office" do
        tasks = ScheduleHearingTask.tasks_for_ro(regional_office)

        expect(tasks.count).to eq(1)
        expect(tasks[0].id).to eq(hearing_task.id)
      end
    end
  end

  context "#update_location_in_vacols" do
    let(:vacols_case) { create(:case, bfcurloc: "57") }
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:task) { create(:schedule_hearing_task, appeal: legacy_appeal) }

    it "when task is put on hold, location is changed to CASEFLOW" do
      expect(vacols_case.bfcurloc).to eq("57")
      task.update!(status: :on_hold)

      expect(vacols_case.reload.bfcurloc).to eq("CASEFLOW")
    end
  end

  context "#update_status_if_children_tasks_are_complete" do
    let(:vacols_case) { create(:case, bfcurloc: "57") }
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:task) { create(:schedule_hearing_task, appeal: legacy_appeal) }
    let!(:child_task) { create(:hearing_admin_action_task, appeal: legacy_appeal, parent: task) }

    it "when children task are completed, location is changed to 57" do
      expect(vacols_case.reload.bfcurloc).to eq("CASEFLOW")
      child_task.update!(status: :completed)

      expect(vacols_case.reload.bfcurloc).to eq("57")
    end
  end
end
