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
      expect(updated_task[0].task_business_payloads.size).to eq 1
      expect(updated_task[0].task_business_payloads[0].description).to eq("Update")
      expect(updated_task[0].task_business_payloads[0].values["regional_office_value"]).to eq("RO13")
      expect(updated_task[0].task_business_payloads[0].values["hearing_date"]).to eq("2018-10-30T00:00:00.000-04:00")
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
end
