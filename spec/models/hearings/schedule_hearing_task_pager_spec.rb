# frozen_string_literal: true

describe Hearings::ScheduleHearingTaskPager, :all_dbs do
  let(:assignee) { HearingsManagement.singleton }
  let(:regional_office_key) { "RO18" }
  let(:legacy_task_pager) { Hearings::ScheduleHearingTaskPager.new(legacy_arguments) }
  let(:ama_task_pager) { Hearings::ScheduleHearingTaskPager.new(ama_arguments) }
  let(:legacy_arguments) do
    {
      assignee: assignee,
      tab_name: Constants.QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME,
      regional_office_key: regional_office_key
    }
  end
  let(:ama_arguments) do
    {
      assignee: assignee,
      tab_name: Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME,
      regional_office_key: regional_office_key
    }
  end
  let(:legacy_appeal1) do
    create(
      :legacy_appeal,
      vacols_case: create(
        :case,
        :type_cavc_remand,
        bfcorlid: "123454787S",
        bfcurloc: "CASEFLOW",
        folder: create(
          :folder,
          ticknum: "91",
          tinum: "1545678",
          titrnum: "123454787S"
        )
      ),
      closest_regional_office: regional_office_key
    )
  end
  let(:legacy_appeal2) do
    create(
      :legacy_appeal,
      vacols_case: create(
        :case,
        :aod,
        :type_original,
        bfcorlid: "123454788S",
        bfcurloc: "CASEFLOW",
        folder: create(
          :folder,
          ticknum: "92",
          tinum: "1645678",
          titrnum: "123454788S"
        )
      ),
      closest_regional_office: regional_office_key
    )
  end
  let(:legacy_appeal3) do
    create(
      :legacy_appeal,
      vacols_case: create(
        :case,
        :aod,
        :type_original,
        bfcorlid: "323454787S",
        bfcurloc: "CASEFLOW",
        folder: create(
          :folder,
          ticknum: "93",
          tinum: "1645001",
          titrnum: "323454787S"
        )
      ),
      closest_regional_office: regional_office_key
    )
  end
  let(:ama_appeal1) do
    create(
      :appeal,
      receipt_date: Time.zone.yesterday - 1,
      closest_regional_office: regional_office_key
    )
  end
  let(:ama_appeal2) do
    create(
      :appeal,
      :advanced_on_docket_due_to_age,
      receipt_date: Time.zone.yesterday - 1,
      closest_regional_office: regional_office_key
    )
  end

  let(:ama_appeal3) do
    create(
      :appeal,
      receipt_date: Time.zone.yesterday,
      closest_regional_office: regional_office_key
    )
  end
  let!(:task1) { create(:schedule_hearing_task, assigned_to: assignee, appeal: legacy_appeal1) }
  let!(:task2) { create(:schedule_hearing_task, assigned_to: assignee, appeal: legacy_appeal2) }
  let!(:task3) { create(:schedule_hearing_task, assigned_to: assignee, appeal: legacy_appeal3) }
  let!(:task4) { create(:schedule_hearing_task, assigned_to: assignee, appeal: ama_appeal1) }
  let!(:task5) { create(:schedule_hearing_task, assigned_to: assignee, appeal: ama_appeal2) }
  let!(:task6) { create(:schedule_hearing_task, assigned_to: assignee, appeal: ama_appeal3) }

  let!(:veteran1) { create(:veteran, file_number: "123454787") }
  let!(:veteran2) { create(:veteran, file_number: "123454788") }
  let!(:veteran3) { create(:veteran, file_number: "323454787") }

  let(:legacy_tasks) { legacy_task_pager.tasks_for_tab }
  let(:ama_tasks) { ama_task_pager.tasks_for_tab }
  let(:cache_legacy_appeals) { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }
  let(:cache_ama_appeals) { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

  describe ".appeal_type" do
    context "legacy tab" do
      subject { legacy_task_pager.appeal_type }
      it "returns 'LegacyAppeal" do
        expect(subject).to eq(LegacyAppeal.name)
      end
    end
    context "ama tab" do
      subject { ama_task_pager.appeal_type }
      it "returns 'Appeal" do
        expect(subject).to eq(Appeal.name)
      end
    end
  end

  describe ".tasks_for_tab" do
    context "legacy tab" do
      subject { legacy_tasks }
      it "returns correct tasks" do
        cache_legacy_appeals
        expect(subject.select(&:id)).to include(task1, task2, task3)
      end
    end
    context "ama tab" do
      subject { ama_tasks }
      it "returns correct tasks" do
        cache_ama_appeals
        expect(subject.select(&:id)).to include(task4, task5, task6)
      end
    end
  end

  describe ".sorted_tasks" do
    context "legacy tab" do
      subject { legacy_task_pager.sorted_tasks(legacy_tasks) }

      it "sorts in CAVC, AOD, and docket_number order" do
        cache_legacy_appeals
        expect(subject.select(&:id)).to eq([task1, task3, task2])
      end
    end
    context "ama tab" do
      subject { ama_task_pager.sorted_tasks(ama_tasks) }

      it "sorts in AOD, docket_number order" do
        cache_ama_appeals
        expect(subject.select(&:id)).to eq([task5, task4, task6])
      end
    end
  end
end
