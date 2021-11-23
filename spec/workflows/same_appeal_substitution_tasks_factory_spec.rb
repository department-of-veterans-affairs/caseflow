# frozen_string_literal: true

describe SameAppealSubstitutionTasksFactory, :postgres do
  let!(:hearing_appeal) do
    create(:appeal,
           :hearing_docket,
           :assigned_to_judge,
           associated_judge: judge)
  end
  let!(:schedule_hearing_task) { hearing_appeal.tasks.of_type(:ScheduleHearingTask)[0] }
  let(:judge) { create(:user, :judge) }
  let(:created_by) { create(:user) }

  describe "#create_substitute_tasks!" do
    context "when created_by is a COB admin" do
      before do
        OrganizationsUser.make_user_admin(created_by, ClerkOfTheBoard.singleton)
      end
      context "when an appeal has already been distributed" do
        let(:selected_task_ids) { [] }
        subject { SameAppealSubstitutionTasksFactory.new(appeal, selected_task_ids, created_by).create_substitute_tasks! }

        context "when it is a hearing lane appeal with hearing tasks selected" do
          let(:appeal) { hearing_appeal }
          let(:selected_task_ids) { [schedule_hearing_task.id] }
          it "sends the case back to distribution" do
            subject
            expect(appeal.ready_for_distribution?).to be true
            judge_tasks = [:JudgeAssignTask, :JudgeDecisionReviewTask]
            # binding.pry
            expect(appeal.tasks.of_type(judge_tasks).open.empty?).to be true
          end
        end
      end
    end
  end

  describe "#selected_tasks_include_hearing_tasks?" do
    subject { SameAppealSubstitutionTasksFactory.new(appeal, selected_task_ids, created_by).selected_tasks_include_hearing_tasks? }

    context "when hearing tasks are selected" do
      let(:appeal) { hearing_appeal }
      let(:selected_task_ids) { [schedule_hearing_task.id] }
      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when no hearing tasks are selected" do
      let(:appeal) do
        create(:appeal,
               :hearing_docket,
               :mail_blocking_distribution,
               associated_judge: judge)
      end
      let!(:extension_request_mail_task) { appeal.tasks.of_type(:ExtensionRequestMailTask)[0] }
      let(:selected_task_ids) { [extension_request_mail_task.id] }
      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end
