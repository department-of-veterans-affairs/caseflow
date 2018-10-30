describe ScheduleHearingTask do
  let(:appeal) { create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
  let!(:hearings_user) do
    create(:hearings_coordinator)
  end
  let!(:hearings_org) do
    create(:hearings_management)
  end
  let!(:staff_mapping) do
    create(:hearings_staff, organization_id: hearings_org.id)
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
end
