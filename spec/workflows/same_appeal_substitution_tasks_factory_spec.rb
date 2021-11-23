# frozen_string_literal: true

describe SameAppealSubstitutionTasksFactory, :postgres do
  before { JudgeTeam.for_judge(judge).add_user(attorney) }

  let(:hearing_appeal) { create(:appeal, :hearing_docket, :assigned_to_judge, associated_judge: judge) }

  let!(:schedule_hearing_task) { hearing_appeal.tasks.of_type(:ScheduleHearingTask)[0] }
  let(:judge) { create(:user, :judge) }
  let(:attorney) { create(:user, :with_vacols_attorney_record) }
  let(:created_by) { create(:user) }

  describe "#create_substitute_tasks!" do
    context "when created_by is a COB admin" do
      before do
        OrganizationsUser.make_user_admin(created_by, ClerkOfTheBoard.singleton)
      end
      context "when an appeal has already been distributed" do
        let(:selected_task_ids) { [] }
        subject do
          SameAppealSubstitutionTasksFactory.new(appeal, selected_task_ids, created_by).create_substitute_tasks!
        end

        context "when it is a hearing lane appeal with hearing tasks selected" do
          let(:appeal) { hearing_appeal }
          let(:selected_task_ids) { [schedule_hearing_task.id] }
          it "sends the case back to distribution" do
            subject
            expect(appeal.ready_for_distribution?).to be true
            judge_tasks = [:JudgeAssignTask, :JudgeDecisionReviewTask]
            expect(appeal.tasks.of_type(judge_tasks).open.empty?).to be true
          end
        end

        context "when it is an appeal with no tasks selected" do
          let(:appeal) do
            create(:appeal,
                   :direct_review_docket,
                   :at_attorney_drafting,
                   associated_judge: judge,
                   associated_attorney: attorney)
          end
          context "when there are open decision tasks" do
            it "maintains the existing open decision tasks" do
              original_open_attorney_task = appeal.tasks.of_type(:AttorneyTask).open[0]
              original_open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open[0]

              subject

              expect(appeal.tasks.of_type(:AttorneyTask).open.length).to equal(1)
              expect(appeal.tasks.of_type(:AttorneyTask).open[0]).to eq(original_open_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open[0]).to eq(original_open_judge_task)
            end
          end
          context "when there are no open decision tasks" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:completed!)
            end
            it "reopens all closed decision tasks" do
              original_judge_assignment = appeal.tasks.of_type(:JudgeDecisionReviewTask)[0].assigned_to

              subject

              open_attorney_tasks = appeal.tasks.of_type(:AttorneyTask).open
              open_attorney_task = open_attorney_tasks[0]
              closed_attorney_task = appeal.tasks.of_type(:AttorneyTask).closed[0]
              open_judge_review_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open[0]

              expect(open_attorney_tasks.size).to eq(1)
              expect(open_attorney_task.status).to eq(Constants.TASK_STATUSES.assigned)
              expect(open_attorney_task.parent.status).to eq(Constants.TASK_STATUSES.on_hold)
              expect(open_attorney_task.assigned_to).to eq(closed_attorney_task.assigned_to)
              expect(open_judge_review_task.assigned_to).to eq(original_judge_assignment)
            end
          end
        end
      end
    end
  end

  describe "#selected_tasks_include_hearing_tasks?" do
    subject do
      SameAppealSubstitutionTasksFactory.new(appeal, selected_task_ids, created_by)
        .selected_tasks_include_hearing_tasks?
    end

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
