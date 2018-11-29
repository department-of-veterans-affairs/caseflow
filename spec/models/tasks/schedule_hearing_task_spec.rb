describe ScheduleHearingTask do
  before do
    FeatureToggle.enable!(:test_facols)
    Time.zone = "Eastern Time (US & Canada)"
    RequestStore[:current_user] = hearings_user
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:vacols_case) do
    FactoryBot.create(:case)
  end
  let(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end
  let!(:hearings_user) do
    create(:hearings_coordinator)
  end
  let(:staff) do
    create(:staff, sdomainid: "BVATWARNER", slogid: "TWARNER")
  end
  let!(:hearings_org) do
    create(:hearings_management)
  end

  let(:test_hearing_date_vacols) do
    Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.local(2018, 11, 2, 5, 0, 0)
    end
  end

  describe "Add a schedule hearing task" do
    let(:root_task) { FactoryBot.create(:root_task, appeal_type: LegacyAppeal.name, appeal: appeal) }
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

    it "should create a taks of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)

      expect(hearing_task.type).to eq(ScheduleHearingTask.name)
      expect(hearing_task.appeal_type).to eq(LegacyAppeal.name)
      expect(hearing_task.status).to eq("assigned")
    end
  end

  describe "Add a schedule hearing task without a pre-existing Root Task" do
    let(:params) do
      {
        type: ScheduleHearingTask.name,
        action: "Assign Hearing",
        appeal: appeal,
        assigned_to_type: "User",
        assigned_to_id: hearings_user.id
      }
    end

    it "should create a root task and a task of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)
      parent_task = RootTask.find_by(appeal_id: appeal.id)

      expect(hearing_task.type).to eq(ScheduleHearingTask.name)
      expect(hearing_task.appeal_type).to eq(LegacyAppeal.name)
      expect(hearing_task.status).to eq("assigned")
      expect(hearing_task.parent_id).to eq(parent_task.id)
      expect(parent_task.appeal_type).to eq(LegacyAppeal.name)
    end
  end

  describe "Add a schedule hearing task with a business payload" do
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
            "regional_office": "RO17",
            "hearing_date": "2018-10-25",
            "hearing_time": "8:00"
          }
        }
      }
    end

    it "should create a taks of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)

      expect(hearing_task.type).to eq(ScheduleHearingTask.name)
      expect(hearing_task.appeal_type).to eq(LegacyAppeal.name)
      expect(hearing_task.status).to eq("assigned")
      expect(hearing_task.task_business_payloads.size).to eq 1
      expect(hearing_task.task_business_payloads[0].description).to eq("test")
      expect(hearing_task.task_business_payloads[0].values["regional_office"]).to eq("RO17")
      expect(hearing_task.task_business_payloads[0].values["hearing_date"]).to eq("2018-10-25")
      expect(hearing_task.task_business_payloads[0].values["hearing_time"]).to eq("8:00")
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

    it "should create a taks of type ScheduleHearingTask" do
      hearing_task = ScheduleHearingTask.create_from_params(params, hearings_user)
      updated_task = hearing_task.update_from_params(update_params, hearings_user)

      expect(updated_task[0].type).to eq(ScheduleHearingTask.name)
      expect(updated_task[0].appeal_type).to eq(LegacyAppeal.name)
      expect(updated_task[0].status).to eq("completed")
      expect(updated_task[0].task_business_payloads.size).to eq 1
      expect(updated_task[0].task_business_payloads[0].description).to eq("Update")
      expect(updated_task[0].task_business_payloads[0].values["regional_office_value"]).to eq("RO13")
      expect(updated_task[0].task_business_payloads[0].values["hearing_date"]).to eq("2018-10-30T00:00:00.000-04:00")
    end
  end

  describe "A Central Office hearing should be updated with vacols_id and appeal placed in location 36" do
    let!(:hearing) { FactoryBot.create(:case_hearing, hearing_type: "C", hearing_date: test_hearing_date_vacols) }
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

    it "should create a taks of type ScheduleHearingTask" do
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

    it "should create a taks of type ScheduleHearingTask" do
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
end
