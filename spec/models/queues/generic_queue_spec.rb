# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe GenericQueue, :all_dbs do
  describe "#tasks" do
    let(:atty) { create(:user) }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: atty.css_id) }
    let(:user) { create(:user) }
    let!(:on_hold_task) do
      create(
        :colocated_task,
        :on_hold,
        assigned_by: atty,
        assigned_to: user,
        on_hold_duration: 3
      )
    end
    let(:task_count) { 5 }

    before { create_list(:colocated_task, task_count, :in_progress, assigned_by: atty, assigned_to: user) }

    context "when some on hold tasks have expired" do
      it "should set the status of the expired task to in_progress" do
        on_hold_task.update(placed_on_hold_at: 15.days.ago)
        tasks = GenericQueue.new(user: user).tasks
        expect(tasks.size).to eq(task_count + 1)

        expired_on_hold_task = tasks.detect { |t| t.id == on_hold_task.id }
        expect(expired_on_hold_task.status).to eq("in_progress")
      end
    end
  end
end
