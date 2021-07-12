# frozen_string_literal: true

describe AppealsWithNoTasksOrAllTasksOnHoldQuery, :postgres do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_one_task) { create(:root_task, :assigned).appeal }
  let!(:appeal_with_two_tasks_not_distribution) do
    appeal = create(:appeal)
    create(:root_task, appeal: appeal)
    create(:track_veteran_task, :assigned, appeal: appeal)
    appeal
  end
  let!(:appeal_with_tasks) { create(:appeal, :with_post_intake_tasks) }
  let!(:appeal_with_all_tasks_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    hearing_task = create(:hearing_task, parent: appeal.root_task)
    schedule_hearing_task = create(:schedule_hearing_task, parent: hearing_task)
    appeal.root_task.descendants.each(&:on_hold!)
    schedule_hearing_task.completed!
    appeal
  end
  let!(:appeal_with_fully_on_hold_subtree) do
    appeal = create(:appeal, :with_post_intake_tasks)
    task = create(:privacy_act_task, appeal: appeal, parent: appeal.root_task)
    task.descendants.each(&:on_hold!)
    appeal
  end
  let!(:appeal_with_failed_reactivated_task) do
    appeal = create(:appeal, :with_post_intake_tasks)
    task1 = create(:privacy_act_task, appeal: appeal, parent: appeal.root_task)
    task1.descendants.each(&:on_hold!)
    task2 = create(:privacy_act_task, appeal: appeal, parent: task1)
    task2.descendants.each(&:completed!)
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
  let!(:incompletely_dispatched_appeal_on_hold) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:bva_dispatch_task, :completed, appeal: appeal)
    appeal
  end

  describe "#call" do
    subject { described_class.new.call }

    let(:stuck_appeals) do
      [
        appeal_with_zero_tasks,
        appeal_with_one_task,
        appeal_with_all_tasks_on_hold,
        appeal_with_fully_on_hold_subtree,
        appeal_with_failed_reactivated_task,
        appeal_with_two_tasks_not_distribution,
        dispatched_appeal_on_hold
      ]
    end

    it "returns array of appeals that look stuck" do
      expect(subject).to match_array(stuck_appeals)
    end
  end

  describe "#ama_appeal_stuck?" do
    subject { described_class.new.ama_appeal_stuck?(appeal) }

    context "appeal_with_zero_tasks" do
      let(:appeal) { appeal_with_zero_tasks }

      it { is_expected.to eq(true) }
    end

    context "appeal_with_tasks" do
      let(:appeal) { appeal_with_tasks }

      it { is_expected.to eq(false) }
    end

    context "appeal_with_all_tasks_on_hold" do
      let(:appeal) { appeal_with_all_tasks_on_hold }

      it { is_expected.to eq(true) }
    end

    context "appeal_with_fully_on_hold_subtree" do
      let(:appeal) { appeal_with_fully_on_hold_subtree }

      it { is_expected.to eq(true) }
    end

    context "appeal_with_failed_reactivated_task" do
      let(:appeal) { appeal_with_failed_reactivated_task }

      it { is_expected.to eq(true) }
    end

    context "appeal_with_decision_documents" do
      let(:appeal) { appeal_with_decision_documents }

      it { is_expected.to eq(false) }
    end

    context "dispatched_appeal_on_hold" do
      let(:appeal) { dispatched_appeal_on_hold }

      it { is_expected.to eq(true) }
    end

    context "incompletely_dispatched_appeal_on_hold" do
      let(:appeal) { incompletely_dispatched_appeal_on_hold }

      it { is_expected.to eq(false) }
    end
  end
end
