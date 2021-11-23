# frozen_string_literal: true

describe SameAppealSubstitutionTasksFactory, :postgres do
  before { JudgeTeam.for_judge(judge).add_user(attorney) }

  let(:hearing_appeal) { create(:appeal, :hearing_docket, :assigned_to_judge, associated_judge: judge) }

  let!(:schedule_hearing_task) { hearing_appeal.tasks.of_type(:ScheduleHearingTask).first }

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
          context "when there is only one open JudgeDecisionReviewTask and one open AttorneyTask" do
            it "maintains the existing open decision tasks" do
              original_open_attorney_task = appeal.tasks.of_type(:AttorneyTask).open.first
              original_open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

              subject

              expect(appeal.tasks.of_type(:AttorneyTask).open.length).to equal(1)
              expect(appeal.tasks.of_type(:AttorneyTask).open.first).to eq(original_open_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first).to eq(original_open_judge_task)
            end
          end
          context "when there is only one closed JudgeDecisionReviewTask and one closed AttorneyTask" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:completed!)
            end
            it "reopens all closed decision tasks" do
              original_judge_assignment = appeal.tasks.of_type(:JudgeDecisionReviewTask).first.assigned_to

              subject

              open_attorney_tasks = appeal.tasks.of_type(:AttorneyTask).open
              open_attorney_task = open_attorney_tasks.first
              closed_attorney_task = appeal.tasks.of_type(:AttorneyTask).closed.first
              open_judge_review_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

              expect(open_attorney_tasks.size).to eq(1)
              expect(open_attorney_task.status).to eq(Constants.TASK_STATUSES.assigned)
              expect(open_attorney_task.parent.status).to eq(Constants.TASK_STATUSES.on_hold)
              expect(open_attorney_task.assigned_to).to eq(closed_attorney_task.assigned_to)
              expect(open_judge_review_task.assigned_to).to eq(original_judge_assignment)
            end
          end
          context "when there are multiple closed JudgeDecisionReviewTask and AttorneyTasks" do
            let(:judge_two) { create(:user, :judge) }
            let(:attorney_two) { create(:user, :with_vacols_attorney_record) }

            before do
              JudgeTeam.for_judge(judge_two).add_user(attorney_two)
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:completed!)
              decision_task = JudgeDecisionReviewTask.create!(appeal: appeal, parent: appeal.root_task,
                                                              assigned_to: judge_two)
              AttorneyTask.create!(appeal: appeal, parent: decision_task,
                                   assigned_by: judge_two, assigned_to: attorney_two)
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:completed!)
            end
            it "reopens the most recently created AttorneyTask and JudgeDecisionReviewTask" do
              recent_attorney_task = appeal.tasks.of_type(:AttorneyTask).closed.order(:id).last
              recent_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).closed.order(:id).last

              subject

              open_attorney_task = appeal.tasks.of_type(:AttorneyTask).open.first
              open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

              # this may fail on status
              expect(open_attorney_task.assigned_to).to eq(recent_attorney_task.assigned_to)
              expect(open_attorney_task.assigned_by).to eq(recent_attorney_task.assigned_by)
              expect(open_judge_task.assigned_to).to eq(recent_judge_task.assigned_to)
              expect(open_judge_task.assigned_by).to eq(recent_judge_task.assigned_by)
            end
          end
          context "when there are open and closed JudgeDecisionReviewTasks and AttorneyTasks" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:completed!)
              decision_task = JudgeDecisionReviewTask.create!(appeal: appeal, parent: appeal.root_task,
                                                              assigned_to: judge)
              AttorneyTask.create!(appeal: appeal, parent: decision_task, assigned_by: judge, assigned_to: attorney)
            end
            it "maintains the existing open and closed tasks" do
              original_open_attorney_task = appeal.tasks.of_type(:AttorneyTask).open.first
              original_open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first
              original_closed_attorney_task = appeal.tasks.of_type(:AttorneyTask).closed.first
              original_closed_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).closed.first

              subject

              expect(appeal.tasks.of_type(:AttorneyTask).open.length).to equal(1)
              expect(appeal.tasks.of_type(:AttorneyTask).open.first).to eq(original_open_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first).to eq(original_open_judge_task)
              expect(appeal.tasks.of_type(:AttorneyTask).closed.first).to eq(original_closed_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).closed.first).to eq(original_closed_judge_task)
            end
          end
          context "when there is a closed AttorneyTask and an open JudgeDecisionReviewTask" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
            end
            it "maintains the existing appeal task tree" do
              closed_attorney_task = appeal.tasks.of_type(:AttorneyTask).first
              open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

              subject

              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first).to eq(open_judge_task)
              expect(appeal.tasks.of_type(:AttorneyTask).first).to eq(closed_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.length).to eq(1)
              expect(appeal.tasks.of_type(:AttorneyTask).open.length).to eq(0)
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
      let!(:extension_request_mail_task) { appeal.tasks.of_type(:ExtensionRequestMailTask).first }
      let(:selected_task_ids) { [extension_request_mail_task.id] }
      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end
