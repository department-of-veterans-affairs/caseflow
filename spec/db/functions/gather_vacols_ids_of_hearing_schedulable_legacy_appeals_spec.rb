# frozen_string_literal: true

describe "gather_vacols_ids_of_hearing_schedulable_legacy_appeals" do
  context "Whenever a number of appeals are seeded" do
    let(:legacy_appeals_with_active_sched_task) do
      create_list(:legacy_appeal,
                  5,
                  :with_schedule_hearing_tasks)
    end

    # This should never happen in Caseflow, but from time to time we wind up with
    #  duplicate entries in our task trees. This appeal should only appear once in the
    #  output of this function depsite having 2+ tasks that meet the criteria of our constraints.
    let(:legacy_appeal_with_two_active_sched_tasks) do
      create(:legacy_appeal, :with_schedule_hearing_tasks).tap do |appeal|
        second_hearing_task = HearingTask.create(appeal: appeal, parent: appeal.root_task)
        ScheduleHearingTask.create(appeal: appeal, parent: second_hearing_task)
      end
    end

    let!(:legacy_appeal_with_closed_sched_task) do
      create(
        :legacy_appeal,
        :with_schedule_hearing_tasks,
        vacols_case: create(:case)
      ).tap do |appeal|
        ScheduleHearingTask.find_by(appeal: appeal).completed!
      end
    end

    let!(:legacy_appeal_without_sched_task) { create(:legacy_appeal) }

    # Should not be included
    let!(:ama_appeal_with_sched_task) { create(:appeal, :with_schedule_hearing_tasks) }

    let!(:desired_vacols_ids) { legacy_appeals_with_active_sched_task.pluck(:vacols_id) }

    subject do
      ActiveRecord::Base.connection.execute(
        "SELECT * FROM gather_vacols_ids_of_hearing_schedulable_legacy_appeals()"
      ).first["gather_vacols_ids_of_hearing_schedulable_legacy_appeals"]
    end

    it "only the desired appeals' IDs are returned" do
      # Validate proper formatting
      expect(subject.scan(/'\d*'/).size).to eq desired_vacols_ids.size

      expect(subject.delete("'").split(",")).to match_array(desired_vacols_ids)
    end
  end
end
