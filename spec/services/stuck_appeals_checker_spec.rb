# frozen_string_literal: true

describe StuckAppealsChecker, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
  let!(:appeal_with_all_tasks_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    hearing_task = create(:hearing_task, parent: appeal.root_task)
    create(:schedule_hearing_task, parent: hearing_task)
    appeal.root_task.descendants.each(&:on_hold!)
    appeal
  end
  let!(:appeal_with_decision_documents) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:decision_document, appeal: appeal)
    appeal
  end
  let!(:dispatched_appeal_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:bva_dispatch_task, :completed, appeal: appeal)
    create(:decision_document, citation_number: "A18123456", appeal: appeal)
    appeal
  end
  let!(:appeal_with_fully_on_hold_subtree) do
    appeal = create(:appeal, :with_post_intake_tasks)
    task = create(:privacy_act_task, appeal: appeal, parent: appeal.root_task)
    task.descendants.each(&:on_hold!)
    appeal
  end
  let!(:appeal_with_closed_root_open_child) do
    appeal = create(:appeal, :with_post_intake_tasks)
    appeal.root_task.completed!
    appeal
  end
  let!(:dispatched_appeal_with_open_track_vet) do
    appeal = create(:appeal, :dispatched)
    create(:track_veteran_task, parent: appeal.root_task)
    appeal
  end

  let(:appeals_with_no_active_task) do
    [appeal_with_zero_tasks,
     appeal_with_all_tasks_on_hold,
     dispatched_appeal_on_hold,
     appeal_with_fully_on_hold_subtree]
  end

  let(:appeals_with_closed_root_open_child) do
    [appeal_with_closed_root_open_child, dispatched_appeal_with_open_track_vet]
  end
  let(:acceptable_appeals_with_closed_root_open_child) do
    [dispatched_appeal_with_open_track_vet]
  end

  describe "#call" do
    it "reports 5 appeals stuck" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to match(/AppealsWithNoTasksOrAllTasksOnHoldQuery: 4/)
      expect(subject.report).to include "  Appeal ids: #{appeals_with_no_active_task.pluck(:id).sort}"

      closed_root_appeals_count = appeals_with_closed_root_open_child.size
      expect(subject.report).to match(/AppealsWithClosedRootTaskOpenChildrenQuery: #{closed_root_appeals_count}/)
      non_acceptable_count = (appeals_with_closed_root_open_child - acceptable_appeals_with_closed_root_open_child).size
      expect(subject.report).to match(/ignoring .*: #{non_acceptable_count}/)
      expect(subject.report).not_to match(/"TrackVeteranTask"=>/)
    end
  end
end
