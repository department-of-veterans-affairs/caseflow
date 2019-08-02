# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

RSpec.describe Tasks::PlaceHoldController, :postgres, type: :controller do
  describe "POST tasks/:id/place_hold" do
    let(:user) { create(:user) }

    let(:parent) { create(:generic_task) }
    let(:parent_id) { parent.id }
    let(:days_on_hold) { 30 }
    let(:instructions) { "Placing task on hold for 30 days" }
    let(:params) { { days_on_hold: days_on_hold, instructions: instructions } }

    subject { post(:create, params: { task_id: parent_id, task: params }) }

    before do
      User.authenticate!(user: user)
    end

    context "with the correct parameters" do
      it "creates the TimedHoldTask for the task" do
        subject

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.length).to eq(2)

        expect(parent.reload.status).to eq(Constants.TASK_STATUSES.on_hold)
        timed_hold_task = parent.children.first
        expect(timed_hold_task).to be_a(TimedHoldTask)
        expect(timed_hold_task.instructions).to eq([instructions])
        expect(timed_hold_task.assigned_by).to eq(user)
        expect(timed_hold_task.timer_end_time.to_date).to eq((Time.zone.now + days_on_hold.days).to_date)
      end
    end

    context "with a non-existent parent_id" do
      let(:parent_id) { parent.id + 999 }

      it "returns an error" do
        subject

        expect(response.status).to eq(404)
      end
    end
  end
end
