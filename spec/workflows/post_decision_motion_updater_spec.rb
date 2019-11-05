# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe PostDecisionMotionUpdater, :all_dbs do
  let!(:lit_support_team) { LitigationSupport.singleton }
  let(:judge) { create(:user, full_name: "Judge User", css_id: "JUDGE_1") }
  let!(:motions_atty) { create(:user, full_name: "Motions attorney") }
  let!(:mtv_mail_task) { create(:vacate_motion_mail_task, assigned_to: motions_atty) }
  let(:task) { create(:judge_address_motion_to_vacate_task, :in_progress, parent: mtv_mail_task, assigned_to: judge) }
  let(:vacate_type) { nil }
  let(:disposition) { nil }
  let(:assigned_to_id) { nil }
  let(:hyperlink) { "https://va.gov/fake-link-to-file" }
  let(:instructions) { "formatted instructions from judge" }
  let(:params) do
    {
      vacate_type: vacate_type,
      disposition: disposition,
      assigned_to_id: assigned_to_id,
      instructions: instructions
    }
  end

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    lit_support_team.add_user(motions_atty)
  end

  subject { PostDecisionMotionUpdater.new(task, params) }

  describe "#process" do
    context "when disposition is granted" do
      let(:disposition) { "granted" }
      let(:assigned_to_id) { create(:user).id }

      context "when vacate type is straight vacate and readjudication" do
        let(:vacate_type) { "straight_vacate_and_readjudication" }

        it "should create straight vacate and readjudication attorney task" do
          subject.process
          expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
          abstract_task = AbstractMotionToVacateTask.find_by(parent: task.parent)
          attorney_task = StraightVacateAndReadjudicationTask.find_by(assigned_to_id: assigned_to_id)
          expect(attorney_task).to_not be nil
          expect(attorney_task.parent).to eq abstract_task
          expect(attorney_task.assigned_by).to eq task.assigned_to
          expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
        end
      end

      context "when vacate type is vacate and de novo" do
        let(:vacate_type) { "vacate_and_de_novo" }

        it "should create vacate and de novo attorney task" do
          subject.process
          expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
          abstract_task = AbstractMotionToVacateTask.find_by(parent: task.parent)
          attorney_task = VacateAndDeNovoTask.find_by(assigned_to_id: assigned_to_id)
          expect(attorney_task).to_not be nil
          expect(attorney_task.parent).to eq abstract_task
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
          expect(AbstractMotionToVacateTask.count).to eq 0
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
          expect(AbstractMotionToVacateTask.count).to eq 0
          expect(VacateAndDeNovoTask.count).to eq 0
        end
      end
    end

    context "when disposition is denied" do
      let(:disposition) { "denied" }

      it "should create post decision motion denied attorney task and assign to prev motions atty" do
        subject.process
        expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        abstract_task = AbstractMotionToVacateTask.find_by(parent: task.parent)
        attorney_task = DeniedMotionToVacateTask.find_by(parent: abstract_task)
        expect(attorney_task).to_not be nil
        expect(attorney_task.parent).to eq abstract_task
        expect(attorney_task.assigned_by).to eq task.assigned_to
        expect(attorney_task.assigned_to).to eq mtv_mail_task.assigned_to
        expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
      end

      it "should assign new task to org if prev atty is inactive" do
        motions_atty.update_status!(Constants.USER_STATUSES.inactive)

        subject.process
        expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        abstract_task = AbstractMotionToVacateTask.find_by(parent: task.parent)
        attorney_task = DeniedMotionToVacateTask.find_by(parent: abstract_task)
        expect(attorney_task).to_not be nil
        expect(attorney_task.parent).to eq abstract_task
        expect(attorney_task.assigned_by).to eq task.assigned_to
        expect(attorney_task.assigned_to).to eq LitigationSupport.singleton
        expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
      end
    end

    context "when disposition is dismissed" do
      let(:disposition) { "dismissed" }

      it "should create post decision motion dismissed attorney task" do
        subject.process
        expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        abstract_task = AbstractMotionToVacateTask.find_by(parent: task.parent)
        attorney_task = DismissedMotionToVacateTask.find_by(parent: abstract_task)
        expect(attorney_task).to_not be nil
        expect(attorney_task.parent).to eq abstract_task
        expect(attorney_task.assigned_by).to eq task.assigned_to
        expect(attorney_task.assigned_to).to eq mtv_mail_task.assigned_to
        expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
      end

      it "should assign new task to org if prev atty is inactive" do
        motions_atty.update_status!(Constants.USER_STATUSES.inactive)

        subject.process
        expect(task.reload.status).to eq Constants.TASK_STATUSES.completed
        abstract_task = AbstractMotionToVacateTask.find_by(parent: task.parent)
        attorney_task = DismissedMotionToVacateTask.find_by(parent: abstract_task)
        expect(attorney_task).to_not be nil
        expect(attorney_task.parent).to eq abstract_task
        expect(attorney_task.assigned_by).to eq task.assigned_to
        expect(attorney_task.assigned_to).to eq LitigationSupport.singleton
        expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
      end
    end
  end
end
