# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe WorkQueue::TaskSerializer, :postgres do
  let(:now) { Time.utc(2018, 4, 24, 12, 0, 0) }
  let(:user) { FactoryBot.create(:user) }
  let!(:parent) { FactoryBot.create(:generic_task, assigned_to: user) }
  let(:days_on_hold) { 18 }

  subject { described_class.new(parent).serializable_hash[:data][:attributes] }

  before do
    Timecop.freeze(now)
  end

  after do
    Timecop.return
  end

  describe "#as_json" do
    context "with a timed hold task" do
      it "renders the correct values for a task with a child TimedHoldTask" do
        TimedHoldTask.create!(appeal: parent.appeal, assigned_to: user, days_on_hold: days_on_hold, parent: parent)

        expect(subject[:placed_on_hold_at]).to eq now
        expect(subject[:on_hold_duration]).to eq days_on_hold
      end
    end

    context "when setting on hold values on the task itself" do
      before do
        parent.update!(status: Constants.TASK_STATUSES.on_hold, on_hold_duration: days_on_hold)
      end

      it "renders the correct values for an on hold task" do
        expect(subject[:placed_on_hold_at]).to eq now
        expect(subject[:on_hold_duration]).to eq days_on_hold
      end
    end
  end
end
