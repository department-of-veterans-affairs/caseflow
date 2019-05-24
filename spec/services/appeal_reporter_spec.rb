# frozen_string_literal: true

describe AppealReporter do
  let!(:appeal_with_zero_tasks) { create(:appeal) }
  let!(:appeal_with_tasks) { create(:appeal, :with_tasks) }
  let!(:legacy_appeal_with_zero_tasks) { create(:legacy_appeal, vacols_case: create(:case)) }
  let!(:legacy_appeal_with_tasks) { create(:task, type: "RootTask").appeal }
  let!(:appeal_with_all_tasks_on_hold) do
    appeal = create(:appeal, :with_tasks)
    schedule_hearing_task = create(:schedule_hearing_task, appeal: appeal)
    schedule_hearing_task.parent.update!(parent: appeal.root_task)
    appeal.root_task.descendants.each(&:on_hold!)
    appeal
  end

  describe "#stuck" do
    subject { described_class.new.stuck }

    it "returns array of appeals that look stuck" do
      expect(subject).to match_array([appeal_with_zero_tasks, appeal_with_all_tasks_on_hold])
    end
  end
end
