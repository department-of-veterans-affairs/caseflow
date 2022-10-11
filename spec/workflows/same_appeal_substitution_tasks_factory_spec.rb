# frozen_string_literal: true

describe SameAppealSubstitutionTasksFactory, :postgres do
  before { JudgeTeam.for_judge(judge).add_user(attorney) }

  before(:all) do
    Seeds::NotificationEvents.new.seed!
  end

  let(:hearing_appeal) { create(:appeal, :hearing_docket, :assigned_to_judge, associated_judge: judge) }

  let!(:schedule_hearing_task) { hearing_appeal.tasks.of_type(:ScheduleHearingTask).first }

  let(:judge) { create(:user, :judge) }
  let(:attorney) { create(:user, :with_vacols_attorney_record) }

  let(:created_by) { create(:user) }
  let(:task_params) { {} }

  let(:task_ids) { {} }

  describe "#create_substitute_tasks!" do
    context "when created_by is a COB admin" do
      before do
        OrganizationsUser.make_user_admin(created_by, ClerkOfTheBoard.singleton)
      end
      let(:selected_task_ids) { [] }
      let(:cancelled_task_ids) { [] }
      subject do
        task_ids[:selected] = selected_task_ids
        task_ids[:cancelled] = cancelled_task_ids
        SameAppealSubstitutionTasksFactory.new(appeal,
                                               task_ids,
                                               created_by,
                                               task_params).create_substitute_tasks!
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
              open_judge_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).open.first

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

        context "when the user selects an evidence submission window task" do
          let(:selected_task_id) { appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first.id }
          let(:selected_task_ids) { [selected_task_id] }
          # The veteran must initially be alive when the appeal is created, or FactoryBot won't make all of the
          # required tasks. The veteran is later made deceased in order to mimic a substitution scenario.
          let(:live_veteran) { create(:veteran, file_number: "12121212") }
          let(:esw_end) { "2022-10-22" }
          let!(:task_params) { { selected_task_id.to_s => { "hold_end_date" => esw_end } } }
          let(:esw_end_date) { Time.zone.parse(esw_end) }
          let!(:appeal) do
            create(:appeal, :hearing_docket, :with_post_intake_tasks, :with_evidence_submission_window_task,
                   veteran_file_number: live_veteran.file_number)
          end
          let(:hearing_task) { appeal.tasks.of_type(:HearingTask).first }

          before do
            appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first.cancelled!
            live_veteran.update!(date_of_death: 1.day.ago)
          end

          it "copies the evidence submission window task and makes it a descendant of a new distribution task" do
            subject

            active_esw_tasks = appeal.tasks.active.of_type(:EvidenceSubmissionWindowTask)
            expect(active_esw_tasks.count).to eq(1)
            expect(active_esw_tasks.first.status).to eq(Constants.TASK_STATUSES.assigned)

            closed_esw_task = appeal.tasks.closed.of_type(:EvidenceSubmissionWindowTask).first
            expect(active_esw_tasks.first.instructions).to eq(closed_esw_task.instructions)
            expect(appeal.tasks.open.of_type(:DistributionTask).count).to eq(1)
            expect(appeal.tasks.open.of_type(:DistributionTask).first.status).to eq(Constants.TASK_STATUSES.on_hold)
            expect(active_esw_tasks.first.parent.type).to eq("HearingTask")
            expect(active_esw_tasks.first.parent.status).to eq(Constants.TASK_STATUSES.on_hold)
            expect(appeal.tasks.open.of_type(:DistributionTask).count).to eq(1)
          end

          it "allots all remaining time in the evidence submission window task to the substitute appellant" do
            subject

            esw_task = appeal.tasks.open.of_type(:EvidenceSubmissionWindowTask).first
            expect(esw_task.timer_ends_at).to be_between(
              esw_end_date - 1.day,
              esw_end_date + 1.day
            )
          end

          context "for an appeal at the attorney drafting step" do
            let!(:appeal) do
              create(:appeal, :hearing_docket, :with_post_intake_tasks, :with_evidence_submission_window_task,
                     :at_attorney_drafting, associated_judge: judge, associated_attorney: attorney,
                                            veteran_file_number: live_veteran.file_number)
            end

            before do
              appeal.tasks.closed.of_type(:EvidenceSubmissionWindowTask).first.cancelled!
              live_veteran.update!(date_of_death: 1.day.ago)
            end

            it "cancels decision tasks with a cancellation reason of substitution" do
              expect(appeal.tasks.of_type(:JudgeDecisionReviewTask).first.status).to eq(Constants.TASK_STATUSES.on_hold)
              expect(appeal.tasks.of_type(:AttorneyTask).first.status).to eq(Constants.TASK_STATUSES.assigned)

              subject

              jdr_task = appeal.tasks.of_type(:JudgeDecisionReviewTask).first
              expect(jdr_task.status).to eq(Constants.TASK_STATUSES.cancelled)
              expect(appeal.tasks.of_type(:AttorneyTask).first.status).to eq(Constants.TASK_STATUSES.cancelled)
              judge_atty_tasks = [:JudgeDecisionReviewTask, :AttorneyTask]
              expect(appeal.tasks.of_type(judge_atty_tasks).pluck(:cancellation_reason).uniq).to eq(
                [Constants.TASK_CANCELLATION_REASONS.substitution]
              )
            end
          end
          context "for an appeal at the judge assign step" do
            let!(:appeal) do
              create(:appeal, :hearing_docket, :with_post_intake_tasks, :with_evidence_submission_window_task,
                     :assigned_to_judge, associated_judge: judge, veteran_file_number: live_veteran.file_number)
            end

            it "cancels the JudgeAssignTask with a cancellation reason of substitution" do
              expect(appeal.tasks.of_type(:JudgeAssignTask).first.status).to eq(Constants.TASK_STATUSES.assigned)
              subject
              expect(appeal.tasks.of_type(:JudgeAssignTask).first.status).to eq(Constants.TASK_STATUSES.cancelled)
              expect(appeal.tasks.of_type(:JudgeAssignTask).first.cancellation_reason).to eq(
                Constants.TASK_CANCELLATION_REASONS.substitution
              )
            end
          end
          context "for an appeal with one cancelled and one active JudgeAssignTask" do
            let!(:appeal) do
              create(:appeal, :hearing_docket, :with_post_intake_tasks, :with_evidence_submission_window_task,
                     :assigned_to_judge, associated_judge: judge, veteran_file_number: live_veteran.file_number)
            end
            let(:judge2) { create(:user, :judge) }

            before do
              appeal.tasks.open.of_type(:JudgeAssignTask).first.update(
                cancellation_reason: Constants.TASK_CANCELLATION_REASONS.poa_change
              )
              appeal.tasks.open.of_type(:JudgeAssignTask).first.cancelled!
              create(:ama_judge_assign_task, appeal: appeal, assigned_to: judge2,
                                             parent: appeal.tasks.of_type(:DistributionTask).first)
            end

            it "cancels the JudgeAssignTask that was active with a cancellation reason of substitution" do
              task_id = appeal.tasks.open.of_type(:JudgeAssignTask).first.id

              subject

              task = Task.find(task_id)
              expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)
              expect(task.cancellation_reason).to eq(Constants.TASK_CANCELLATION_REASONS.substitution)
            end

            it "leaves the cancellation reason of the previously cancelled JudgeAssignTask unchanged" do
              task = appeal.tasks.cancelled.of_type(:JudgeAssignTask).first

              subject

              expect(task.cancellation_reason).to eq(Constants.TASK_CANCELLATION_REASONS.poa_change)
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
          context "when there are active tasks" do
            before do
              # Create active tasks that are visible to the user for selection
              EvidenceOrArgumentMailTask.create!(parent: appeal.root_task,
                                                 appeal: appeal,
                                                 assigned_to: User.system_user)
              HearingTask.create!(parent: appeal.root_task, appeal: appeal, assigned_to: User.system_user)
            end
            let(:evidence_task) { appeal.tasks.of_type(:EvidenceOrArgumentMailTask).first }
            let(:hearing_task) { appeal.tasks.of_type(:HearingTask).first }
            let!(:trans_task) { create(:ama_colocated_task, :translation, appeal: appeal, parent: appeal.root_task) }
            let(:cancelled_task_ids) { [evidence_task.id, hearing_task.id] }
            it "cancels active tasks" do
              active_tasks = [
                evidence_task,
                hearing_task
              ]

              subject
              trans_task.reload
              expect(trans_task.cancelled? &&
                trans_task.cancellation_reason.eql?(Constants.TASK_CANCELLATION_REASONS.substitution)).to be false
              expect(
                active_tasks.map(&:reload).all? do |task|
                  task.cancelled? && task.cancellation_reason.eql?(Constants.TASK_CANCELLATION_REASONS.substitution)
                end
              ).to be true
            end
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

        context "with additional hearing tasks and ScheduleHearingTask selected for reopening" do
          let(:appeal) { create(:appeal, :hearing_docket, :with_post_intake_tasks) }
          let(:hearing_task) { appeal.tasks.find_by(type: "HearingTask") }
          let(:schedule_hearing_task) { appeal.tasks.find_by(type: "ScheduleHearingTask") }
          let(:assign_hearing_disposition_task) { create(:assign_hearing_disposition_task, parent: hearing_task) }
          let!(:transcription_task) { create(:transcription_task, parent: assign_hearing_disposition_task) }
          let!(:evidence_submission_window_task) do
            create(:evidence_submission_window_task, parent: assign_hearing_disposition_task)
          end

          let(:selected_task_ids) { [schedule_hearing_task.id] }

          it "cancels related hearing tasks" do
            types_to_cancel = [
              AssignHearingDispositionTask.name,
              ChangeHearingDispositionTask.name,
              EvidenceSubmissionWindowTask.name,
              TranscriptionTask.name
            ]
            tasks_to_cancel = appeal.tasks.select { |task| types_to_cancel.include?(task.type) }

            expect(tasks_to_cancel.all?(&:open?)).to be true

            subject

            expect(
              tasks_to_cancel.map(&:reload).all? do |task|
                task.cancelled? && task.cancellation_reason.eql?(Constants.TASK_CANCELLATION_REASONS.substitution)
              end
            ).to be true
          end
        end
      end
    end
  end

  describe "#resume_evidence_submission" do
    let(:selected_task_id) { appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first.id }
    let(:selected_task_ids) { [selected_task_id] }
    let(:task_ids) { {} }
    # i wish there were a factory for this
    let(:created_by) { create(:user) }
    # The veteran must initially be alive when the appeal is created, or FactoryBot won't make all of the
    # required tasks. The veteran is later made deceased in order to mimic a substitution scenario.
    let(:live_veteran) { create(:veteran, file_number: "12121212") }
    let(:esw_end) { "sOMETHing nOT vaLId" }
    let!(:task_params) { { selected_task_id.to_s => { "hold_end_date" => esw_end } } }
    let!(:appeal) do
      create(:appeal, :with_post_intake_tasks, :with_evidence_submission_window_task,
             veteran_file_number: live_veteran.file_number)
    end

    subject do
      task_ids[:selected] = selected_task_ids
      task_ids[:cancelled] = nil
      SameAppealSubstitutionTasksFactory.new(appeal,
                                             task_ids,
                                             created_by,
                                             task_params).resume_evidence_submission
    end
    before do
      OrganizationsUser.make_user_admin(created_by, ClerkOfTheBoard.singleton)
      appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first.cancelled!
      live_veteran.update!(date_of_death: 1.day.ago)
    end
    context "when esw_task_params['hold_end_date'] is not a valid value" do
      it "throws an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::InvalidParameter)
          expect(error.code).to eq 400
          expect(error.message).to eq("Invalid parameter 'hold_end_date'")
        end
      end
    end
  end

  describe "#hearing_task_selected?" do
    let(:cancelled_task_ids) { [] }
    subject do
      task_ids[:selected] = selected_task_ids
      task_ids[:cancelled] = cancelled_task_ids
      SameAppealSubstitutionTasksFactory.new(appeal, task_ids, created_by, task_params)
        .hearing_task_selected?
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
