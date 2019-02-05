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
      let(:hearing_day) { create(:hearing_day, request_type: "V") }
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
