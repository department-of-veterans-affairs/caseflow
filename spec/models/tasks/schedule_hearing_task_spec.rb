describe ScheduleHearingTask do
  before do
    FeatureToggle.enable!(:test_facols)
    Time.zone = "Eastern Time (US & Canada)"
    OrganizationsUser.add_user_to_organization(hearings_user, HearingsManagement.singleton)
    RequestStore[:current_user] = hearings_user
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:vacols_case) { FactoryBot.create(:case) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let!(:hearings_user) { create(:hearings_coordinator) }
  let(:staff) { create(:staff, sdomainid: "BVATWARNER", slogid: "TWARNER") }
  let!(:hearings_org) { create(:hearings_management) }

  let(:test_hearing_date_vacols) do
    Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.local(2018, 11, 2, 5, 0, 0)
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

    subject { ScheduleHearingTask.create_from_params(params, hearings_user) }

    it "should create a task of type ScheduleHearingTask" do
      expect(subject.type).to eq(ScheduleHearingTask.name)
      expect(subject.appeal_type).to eq(LegacyAppeal.name)
      expect(subject.status).to eq("assigned")
    end

    context "the root task is not a legacy task" do
      let(:appeal) { create :appeal }
      let(:root_task_appeal_type) { Appeal.name }

      it "raises an ActionForbiddenError" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end

    context "the root task has an on hold ScheduleHearingTask child" do
      let!(:on_hold_task) { create(:schedule_hearing_task, parent: root_task, status: Constants.TASK_STATUSES.on_hold) }

      it "raises an ActionForbiddenError" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end
  end

  describe "Add and update a schedule hearing task with a new business payload" do
    let(:hearing) { FactoryBot.create(:case_hearing) }
    let(:root_task) { FactoryBot.create(:root_task, appeal_type: "LegacyAppeal", appeal: appeal) }
    let(:params) do
      {
        type: ScheduleHearingTask.name,
        action: "Assign Hearing",
        appeal: appeal,
        assigned_to_type: "User",
        assigned_to_id: hearings_user.id,
        parent_id: root_task.id,
        business_payloads: {
          description: "test",
          values: {
            "regional_office": "RO13",
            "hearing_date": "2018-10-25",
            "hearing_time": "8:00"
          }
        }
      }
    end
    let(:update_params) do
      {
        status: "completed",
        business_payloads: {
          description: "Update",
          values: {
            "regional_office_value": "RO13",
            "hearing_pkseq": hearing.vdkey,
            "hearing_date": "2018-10-30",
            "hearing_type": "Video"
          }
        }
      }
    end

    it "should create a task of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)
      updated_task = hearing_task.update_from_params(update_params, hearings_user)

      expect(updated_task[0].type).to eq(ScheduleHearingTask.name)
      expect(updated_task[0].appeal_type).to eq(LegacyAppeal.name)
      expect(updated_task[0].status).to eq("completed")
    end
  end

  describe "A Central Office hearing should be updated with vacols_id and appeal placed in location 36" do
    let!(:hearing) do
      FactoryBot.create(:case_hearing,
                        hearing_type: "C",
                        hearing_date: test_hearing_date_vacols,
                        folder_nr: nil)
    end
    let!(:root_task) { FactoryBot.create(:root_task, appeal_type: "LegacyAppeal", appeal: appeal) }
    let!(:params) do
      {
        type: ScheduleHearingTask.name,
        action: "Assign Hearing",
        appeal: appeal,
        assigned_to_type: "User",
        assigned_to_id: hearings_user.id,
        parent_id: root_task.id,
        business_payloads: {
          description: "test",
          values: {
            "regional_office_value": "RO13",
            "hearing_date": "2018-11-02T09:00:00.000-04:00",
            "hearing_type": "Central"
          }
        }
      }
    end
    let!(:update_params) do
      {
        status: "completed",
        business_payloads: {
          description: "Update",
          values: {
            "regional_office_value": "RO13",
            "hearing_date": "2018-11-02T09:00:00.000-04:00",
            "hearing_type": "Central"
          }
        }
      }
    end

    it "should create a task of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)
      hearing_task.update_from_params(update_params, hearings_user)
      updated_hearing = VACOLS::CaseHearing.find(hearing.hearing_pkseq)

      expect(updated_hearing.folder_nr).to eq(appeal.vacols_id)
      expect(updated_hearing.hearing_date).to eq(hearing.hearing_date)
      expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:awaiting_co_hearing]
    end
  end

  describe "A Video hearing should be created and appeal placed in location 38" do
    let(:hearing) { FactoryBot.create(:case_hearing, hearing_date: test_hearing_date_vacols) }
    let(:root_task) { FactoryBot.create(:root_task, appeal_type: "LegacyAppeal", appeal: appeal) }
    let(:params) do
      {
        type: ScheduleHearingTask.name,
        action: "Assign Hearing",
        appeal: appeal,
        assigned_to_type: "User",
        assigned_to_id: hearings_user.id,
        parent_id: root_task.id,
        business_payloads: {
          description: "test",
          values: {
            "regional_office_value": "RO13",
            "hearing_date": "2018-11-02T09:00:00.000-04:00",
            "hearing_type": "Video"
          }
        }
      }
    end
    let(:update_params) do
      {
        status: "completed",
        business_payloads: {
          description: "Update",
          values: {
            "regional_office_value": "RO13",
            "hearing_pkseq": hearing.vdkey,
            "hearing_date": "2018-11-02T09:00:00.000-04:00",
            "hearing_type": "Video"
          }
        }
      }
    end

    it "should create a task of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)
      hearing_task.update_from_params(update_params, hearings_user)
      created_hearing = VACOLS::CaseHearing.find_by(hearing_type: "V",
                                                    folder_nr: appeal.vacols_id)

      expect(created_hearing.vdkey).to eq(hearing.vdkey)
      expect(created_hearing.hearing_date).to eq(hearing.hearing_date)
      expect(created_hearing.folder_nr).to eq(appeal.vacols_id)
      expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:awaiting_video_hearing]
    end
  end

  context "#update_from_params" do
    context "AMA appeal" do
      let(:hearing_day) { create(:hearing_day) }
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
              "hearing_date": "2018-11-02T09:00:00.000-04:00",
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
    end
  end

  context ".tasks_for_ro" do
    let(:regional_office) { "RO17" }
    let(:number_of_cases) { 10 }

    context "when there are legacy cases" do
      let!(:cases) do
        create_list(:case, number_of_cases, bfregoff: regional_office, bfhr: "2", bfcurloc: "57", bfdocind: "V")
      end

      let!(:non_hearing_cases) do
        create_list(:case, number_of_cases)
      end

      it "returns tasks for all relevant appeals in location 57" do
        tasks = ScheduleHearingTask.tasks_for_ro(regional_office)

        expect(tasks.map { |task| task.appeal.vacols_id }).to match_array(cases.pluck(:bfkey))
      end
    end

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
end
