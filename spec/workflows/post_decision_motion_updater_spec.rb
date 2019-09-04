# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe PostDecisionMotionUpdater, :postgres do
  let(:task) { create(:judge_address_motion_to_vacate_task, :in_progress) }
  let(:vacate_type) { nil }
  let(:disposition) { nil }
  let(:assigned_to_id) { nil }
  let(:params) { { vacate_type: vacate_type, disposition: disposition, assigned_to_id: assigned_to_id } }

  subject { PostDecisionMotionUpdater.new(task, params) }

  describe "#process" do
    context "when disposition is not granted" do
      let(:disposition) { "denied" }

      it "should assign motion back to the motions attorney" do
        subject.process
        expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        expect(task.parent.status).to eq Constants.TASK_STATUSES.assigned
      end
    end
    context "when disposition is granted" do
      let(:disposition) { "granted" }
      let(:assigned_to_id) { create(:user).id }

      context "when vacate type is straight vacate and readjudication" do
        let(:vacate_type) { "straight_vacate_and_readjudication" }

        it "should create straight vacate and readjudication attorney task" do
          subject.process
          expect(task.reload.status).to eq Constants.TASK_STATUSES.on_hold
          attorney_task = StraightVacateAndReadjudicationTask.find_by(assigned_to_id: assigned_to_id)
          expect(attorney_task).to_not be nil
          expect(attorney_task.parent).to eq task
          expect(attorney_task.assigned_by).to eq task.assigned_to
          expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
        end
      end

      context "when vacate type is vacate and de novo" do
        let(:vacate_type) { "vacate_and_de_novo" }

        it "should create vacate and de novo attorney task" do
          subject.process
          expect(task.reload.status).to eq Constants.TASK_STATUSES.on_hold
          attorney_task = VacateAndDeNovoTask.find_by(assigned_to_id: assigned_to_id)
          expect(attorney_task).to_not be nil
          expect(attorney_task.parent).to eq task
          expect(attorney_task.assigned_by).to eq task.assigned_to
          expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
        end
      end

      context "when assigned to is missing" do
        let(:vacate_type) { "vacate_and_de_novo" }
        let(:assigned_to_id) { nil }

        it "should not create an attorney task" do
          subject.process
          expect(subject.errors[:assigned_to].first).to eq "can't be blank"
          expect(task.reload.status).to eq Constants.TASK_STATUSES.in_progress
          expect(VacateAndDeNovoTask.count).to eq 0
        end
      end

      context "when vacate type is missing" do
        let(:vacate_type) { nil }
        let(:assigned_to_id) { create(:user).id }

        it "should not create an attorney task" do
          subject.process
          expect(subject.errors[:vacate_type].first).to eq "is required for granted disposition"
          expect(task.reload.status).to eq Constants.TASK_STATUSES.in_progress
          expect(VacateAndDeNovoTask.count).to eq 0
        end
      end
    end
  end
end
