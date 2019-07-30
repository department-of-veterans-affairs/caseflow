# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe InformalHearingPresentationTask, :postgres do
  let(:user) { create(:user, roles: ["VSO"]) }

  describe ".available_actions" do
    subject { task.available_actions(user) }

    context "when task is assigned to user" do
      let(:task) do
        InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task, assigned_to: user).id)
      end

      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      it "should return team assign, person reassign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to an organization the user is a member of" do
      let(:org) { Organization.find(FactoryBot.create(:organization).id) }
      let(:task) do
        InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task, assigned_to: org).id)
      end
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      before { allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true) }
      it "should return team assign, person assign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to user" do
      let(:task) do
        InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task).id)
      end

      let(:expected_actions) do
        []
      end

      it "should return team assign, person reassign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end
  end

  describe "when an IHP task is cancelled" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:task) do
      InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task, assigned_to: user).id)
    end

    before do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end

    it "should create a DistributionTask" do
      task.update!(status: Constants.TASK_STATUSES.cancelled)
      expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      expect(appeal.root_task.reload.children.select { |t| t.type == DistributionTask.name }.count).to eq(1)
    end
  end
end
