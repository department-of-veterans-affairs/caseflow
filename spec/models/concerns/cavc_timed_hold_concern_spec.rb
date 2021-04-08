# frozen_string_literal: true

describe CavcTimedHoldConcern do
  class TestEntity < Task
    include ActiveModel::Model
    include CavcTimedHoldConcern
    attr_accessor :children
  end

  let(:appeal) { create(:appeal, :type_cavc_remand) }
  let(:cavc_task) { appeal.tasks.open.where(type: :CavcTask).last }
  let!(:mdr_task) { MdrTask.create_with_hold(cavc_task) }
  let(:child_timed_hold_task) { mdr_task.children.where(type: :TimedHoldTask).first }
  let(:model) { TestEntity.new }

  describe "#update_timed_hold" do
    subject { mdr_task.update_timed_hold }

    context "when the task calls update_timed_hold" do
      it "it will create a new timed hold task" do
        original_count = TimedHoldTask.count
        
        expect { subject }.not_to raise_error

        expect(TimedHoldTask.count).to eq original_count + 1
      end

      it "it will cancel the existing timed hold task" do
        expect(TimedHoldTask.first.status).to_not eq Constants.TASK_STATUSES.cancelled
        
        expect { subject }.not_to raise_error

        expect(TimedHoldTask.first.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end
  end
end
