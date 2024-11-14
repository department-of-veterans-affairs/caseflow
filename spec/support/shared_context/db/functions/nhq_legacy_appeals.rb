# frozen_string_literal: true

RSpec.shared_context "Legacy appeals that may or may not appear in the NHQ" do
  let(:legacy_appeals_with_active_sched_task) do
    # Not using create_list here since it causes the vacols_case_key sequence not to operate correctly.
    Array.new(5).map do
      create(:legacy_appeal,
             :with_schedule_hearing_tasks,
             :with_veteran,
             vacols_case: create(:case)
            )
    end
  end

  # This should never happen in Caseflow, but from time to time we wind up with
  #  duplicate entries in our task trees. This appeal should only appear once in the
  #  output of this function depsite having 2+ tasks that meet the criteria of our constraints.
  let!(:legacy_appeal_with_two_active_sched_tasks) do
    create(
      :legacy_appeal,
      :with_schedule_hearing_tasks,
      :with_veteran,
      vacols_case: create(:case)
    ).tap do |appeal|
      second_hearing_task = HearingTask.create(appeal: appeal, parent: appeal.root_task)
      ScheduleHearingTask.create(appeal: appeal, parent: second_hearing_task)
    end
  end

  let!(:legacy_appeal_with_closed_sched_task) do
    create(
      :legacy_appeal,
      :with_schedule_hearing_tasks,
      :with_veteran,
      vacols_case: create(:case)
    ).tap do |appeal|
      ScheduleHearingTask.find_by(appeal: appeal).completed!
    end
  end

  let!(:legacy_appeal_without_sched_task) do
    create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: create(:case)
    )
  end

  # Should not be included
  let!(:ama_appeal_with_sched_task) { create(:appeal, :with_schedule_hearing_tasks) }

  let!(:desired_vacols_ids) do
    legacy_appeals_with_active_sched_task.pluck(:vacols_id) + [
      legacy_appeal_with_two_active_sched_tasks.vacols_id
    ]
  end
end
