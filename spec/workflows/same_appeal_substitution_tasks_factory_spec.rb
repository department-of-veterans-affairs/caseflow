# frozen_string_literal: true

describe SameAppealSubstitutionTasksFactory, :postgres do
  before { JudgeTeam.for_judge(judge).add_user(attorney) }

  let(:hearing_appeal) { create(:appeal, :hearing_docket, :assigned_to_judge, associated_judge: judge) }

  let!(:schedule_hearing_task) { hearing_appeal.tasks.of_type(:ScheduleHearingTask).first }

  let(:judge) { create(:user, :judge) }
  let(:attorney) { create(:user, :with_vacols_attorney_record) }

  let(:created_by) { create(:user) }
  let(:task_params) { {} }

  describe "#create_substitute_tasks!" do
    context "when created_by is a COB admin" do
      before do
        OrganizationsUser.make_user_admin(created_by, ClerkOfTheBoard.singleton)
      end
      let(:selected_task_ids) { [] }
      let(:cancelled_task_ids) { [] }
      subject do
        SameAppealSubstitutionTasksFactory.new(appeal,
                                               selected_task_ids,
                                               created_by,
                                               task_params,
                                               cancelled_task_ids).create_substitute_tasks!
      end
      context "when an appeal has already been distributed" do
        context "when it is a hearing lane appeal with hearing tasks selected" do
          let(:appeal) { hearing_appeal }
          let(:selected_task_ids) { [schedule_hearing_task.id] }
          it "sends the case back to distribution" do
            subject

            expect(appeal.ready_for_distribution?).to be true
            judge_tasks = [:JudgeAssignTask, :JudgeDecisionReviewTask]
            expect(appeal.tasks.of_type(judge_tasks).open.empty?).to be true
          end

          it "does not create the selected hearing task" do
            subject

            open_schedule_hearing_tasks = hearing_appeal.tasks.of_type(:ScheduleHearingTask).open
            expect(open_schedule_hearing_tasks.empty?).to be true
          end

          it "cancels any open JudgeAssignTasks" do
            expect(appeal.tasks.of_type(:JudgeAssignTask).open.empty?).to be false

            subject

            expect(appeal.tasks.of_type(:JudgeAssignTask).open.empty?).to be true
          end

          context "with open JudgeDecisionReviewTasks or AttorneyTasks" do
            before do
              decision_task = JudgeDecisionReviewTask.create!(appeal: appeal, parent: appeal.root_task,
                                                              assigned_to: judge)
              AttorneyTask.create!(appeal: appeal, parent: decision_task, assigned_by: judge, assigned_to: attorney)
            end
            it "cancels any open JudgeDecisionReviewTasks and AttorneyTasks" do
              expect(appeal.tasks.of_type(:AttorneyTask).open.empty?).to be false
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.empty?).to be false

              subject

              expect(appeal.tasks.of_type(:AttorneyTask).open.empty?).to be true
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.empty?).to be true
            end
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
          context "when there is only one cancelled JudgeDecisionReviewTask and one cancelled AttorneyTask" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:cancelled!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:cancelled!)
            end
            it "reopens all cancelled decision tasks" do
              original_judge_assignment = appeal.tasks.of_type(:JudgeDecisionReviewTask).first.assigned_to

              subject

              open_attorney_tasks = appeal.tasks.of_type(:AttorneyTask).open
              open_attorney_task = open_attorney_tasks.first
              closed_attorney_task = appeal.tasks.of_type(:AttorneyTask).cancelled.first
              open_judge_review_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

              expect(open_attorney_tasks.size).to eq(1)
              expect(open_attorney_task.status).to eq(Constants.TASK_STATUSES.assigned)
              expect(open_attorney_task.parent.status).to eq(Constants.TASK_STATUSES.on_hold)
              expect(open_attorney_task.assigned_to).to eq(closed_attorney_task.assigned_to)
              expect(open_judge_review_task.assigned_to).to eq(original_judge_assignment)
            end
          end
          context "when there are multiple cancelled JudgeDecisionReviewTasks and AttorneyTasks" do
            let(:judge_two) { create(:user, :judge) }
            let(:attorney_two) { create(:user, :with_vacols_attorney_record) }

            before do
              JudgeTeam.for_judge(judge_two).add_user(attorney_two)
              appeal.tasks.of_type(:AttorneyTask).open.each(&:cancelled!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:cancelled!)
              decision_task = JudgeDecisionReviewTask.create!(appeal: appeal, parent: appeal.root_task,
                                                              assigned_to: judge_two, instructions: ["most recent"])
              AttorneyTask.create!(appeal: appeal, parent: decision_task,
                                   assigned_by: judge_two, assigned_to: attorney_two, instructions: ["most recent"])
              appeal.tasks.of_type(:AttorneyTask).open.each(&:cancelled!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:cancelled!)
            end
            it "reopens the most recently created AttorneyTask and JudgeDecisionReviewTask" do
              recent_attorney_task = appeal.tasks.of_type(:AttorneyTask).cancelled.order(:id).last
              recent_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).cancelled.order(:id).last
              subject
              open_attorney_task = appeal.tasks.of_type(:AttorneyTask).open.first
              open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.last

              expect(open_attorney_task.instructions).to eq(recent_attorney_task.instructions)
              expect(open_judge_task.instructions).to eq(recent_judge_task.instructions)
            end
          end
          context "when there are open and cancelled JudgeDecisionReviewTasks and AttorneyTasks" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:cancelled!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:cancelled!)
              decision_task = JudgeDecisionReviewTask.create!(appeal: appeal, parent: appeal.root_task,
                                                              assigned_to: judge)
              AttorneyTask.create!(appeal: appeal, parent: decision_task, assigned_by: judge, assigned_to: attorney)
            end
            it "maintains the existing open and cancelled tasks" do
              original_open_attorney_task = appeal.tasks.of_type(:AttorneyTask).open.first
              original_open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first
              original_closed_attorney_task = appeal.tasks.of_type(:AttorneyTask).cancelled.first
              original_closed_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).cancelled.first

              subject

              expect(appeal.tasks.of_type(:AttorneyTask).open.length).to equal(1)
              expect(appeal.tasks.of_type(:AttorneyTask).open.first).to eq(original_open_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first).to eq(original_open_judge_task)
              expect(appeal.tasks.of_type(:AttorneyTask).cancelled.first).to eq(original_closed_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).cancelled.first).to eq(original_closed_judge_task)
            end
          end
          context "when there is a cancelled AttorneyTask and an open JudgeDecisionReviewTask" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:cancelled!)
            end
            it "maintains the existing appeal task tree" do
              cancelled_attorney_task = appeal.tasks.of_type(:AttorneyTask).first
              open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

              subject

              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first).to eq(open_judge_task)
              expect(appeal.tasks.of_type(:AttorneyTask).first).to eq(cancelled_attorney_task)
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).open.length).to eq(1)
              expect(appeal.tasks.of_type(:AttorneyTask).open.length).to eq(0)
            end
          end
          context "when there is one completed AttorneyTask and one completed JudgeDecisionReviewTask" do
            before do
              appeal.tasks.of_type(:AttorneyTask).open.each(&:completed!)
              appeal.tasks.of_type(:JudgeDecisionReviewTask).open.each(&:completed!)
            end
            it "does not reopen the completed tasks" do
              subject

              open_attorney_tasks = appeal.tasks.of_type(:AttorneyTask).open
              open_judge_review_tasks = appeal.tasks.of_type(:JudgeDecisionReviewTask).open

              expect(open_attorney_tasks.empty?).to be true
              expect(open_judge_review_tasks.empty?).to be true
            end
          end
        end
      end

      context "when an appeal has not been distributed" do
        let(:appeal) { create(:appeal, :with_post_intake_tasks) }
        context "when the user selects no tasks" do
          it "leaves the appeal tree unchanged" do
            task_count = appeal.tasks.count
            open_task_count = appeal.tasks.open.count

            subject

            expect(appeal.tasks.count).to eq(task_count)
            expect(appeal.tasks.open.count).to eq(open_task_count)
          end
        end
        context "when the user selects a task assigned to an individual" do
          before do
            EngineeringTask.create!(parent: appeal.root_task, appeal: appeal, assigned_to: User.system_user)
          end
          let(:eng_task) { appeal.tasks.of_type(:EngineeringTask).first }
          let(:selected_task_ids) { [eng_task.id] }
          it "throws an error" do
            expect { subject }.to raise_error("Expecting only tasks assigned to organizations")
          end
        end
        context "when the user selects a task assigned to a group" do
          let(:appeal) { create(:appeal, :with_post_intake_tasks) }
          let(:translation_task) { create(:ama_colocated_task, :translation, appeal: appeal, parent: appeal.root_task) }
          let(:selected_task_ids) { [translation_task.id] }
          before do
            translation_task.children.of_type(:TranslationTask).first.cancelled!
          end
          it "copies the task" do
            first_translation_task = appeal.tasks.of_type(:TranslationTask).first

            subject

            second_translation_task = appeal.tasks.open.of_type(:TranslationTask).first
            expect(first_translation_task.id).to_not eq(second_translation_task.id)
            expect(second_translation_task.placed_on_hold_at).to be_nil
            expect(second_translation_task.status).to eq(Constants.TASK_STATUSES.assigned)
          end
        end
      end
    end
  end

  describe "#selected_tasks_include_hearing_tasks?" do
    let(:cancelled_task_ids) { [] }
    subject do
      SameAppealSubstitutionTasksFactory.new(appeal, selected_task_ids, created_by, task_params, cancelled_task_ids)
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
