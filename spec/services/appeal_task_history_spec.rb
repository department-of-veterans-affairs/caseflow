# frozen_string_literal: true

describe AppealTaskHistory, :postgres do
  let(:appeal) { create(:appeal, :with_post_intake_tasks) }
  let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks) }
  let(:appeal_task) { appeal.tasks.find { |task| task.type == "DistributionTask" } }
  let(:legacy_appeal_task) { legacy_appeal.tasks.find { |task| task.type == "ScheduleHearingTask" } }
  let(:user) { create(:user) }

  before do
    PaperTrail.request.whodunnit = user.id
    Timecop.freeze(Time.zone.now) # don't bother tracking timestamp changes in specs
  end

  describe "#history" do
    context "when Task changes" do
      before do
        appeal_task.update!(assigned_to: user, status: Constants.TASK_STATUSES.assigned)
        legacy_appeal_task.update!(assigned_to: user, status: Constants.TASK_STATUSES.assigned)
      end

      let(:diff) do
        { "placed_on_hold_at" => [nil, Time.zone.now], "status" => %w[assigned on_hold] }
      end

      it "records the changeset" do
        appeal_history = appeal.history
        expect(appeal_history).to be_a(described_class)

        legacy_appeal_history = legacy_appeal.history
        expect(legacy_appeal_history).to be_a(described_class)

        expect(appeal_history.events.length).to eq(3)
        expect(legacy_appeal_history.events.length).to eq(3)

        appeal_event = appeal_history.events[1]
        expect(appeal_event).to be_a(TaskEvent)
        expect(appeal_event.who).to eq(user)
        expect(appeal_event.summary).to match(/\[#{user.css_id}\]/)
        expect(appeal_event.diff).to eq(diff)

        legacy_appeal_event = legacy_appeal_history.events[1]
        expect(legacy_appeal_event).to be_a(TaskEvent)
        expect(legacy_appeal_event.who).to eq(user)
        expect(legacy_appeal_event.summary).to match(/\[#{user.css_id}\]/)
        expect(legacy_appeal_event.diff).to eq(diff)
      end
    end
  end
end
