# frozen_string_literal: true

describe "Timed Hold Task example", :postgres do
  include SQLHelpers

  context "one TimedHoldTask exists with a TaskTimer" do
    let!(:timed_hold_task) do
      # we want the TaskTimer auto-creation to work so we don't use
      # the :timed_hold_task factory here.
      TimedHoldTask.create!(
        appeal: create(:appeal),
        assigned_to: create(:user),
        parent: create(:ama_task),
        days_on_hold: 30
      )
    end

    it "generates correct report" do
      expect_sql("timed-hold-task").to include(
        hash_including(
          "timer_will_trigger" => timed_hold_task.task_timers.first.as_hash[:last_submitted_at]
        )
      )
    end
  end
end
