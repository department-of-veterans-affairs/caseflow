# frozen_string_literal: true

describe BlockedSpecialCaseMovementTask do
  describe ".create" do
    context "with Case Movement Team user" do
      let(:cm_user) { create(:user) }

      subject do
        BlockedSpecialCaseMovementTask.create!(appeal: appeal,
                                               assigned_to: cm_user,
                                               assigned_by: cm_user,
                                               parent: dist_task)
      end

      before do
        SpecialCaseMovementTeam.singleton.add_user(cm_user)
      end

      shared_examples "completed distribution and at JudgeAssign" do
        it "should create the SCM task and JudgeAssign task" do
          expect { subject }.not_to raise_error
          scm_task =  appeal.tasks.where(type: BlockedSpecialCaseMovementTask.name).first
          expect(scm_task.status).to eq(Constants.TASK_STATUSES.completed)
          judge_task = appeal.tasks.open.where(type: JudgeAssignTask.name).first
          expect(judge_task.status).to eq(Constants.TASK_STATUSES.assigned)
        end
      end

      shared_examples "cancelled distribution children" do
        it "cancel any open distribution descendants" do
          dist_task = appeal.tasks.open.where(type: DistributionTask.name).first
          open_tasks = dist_task.descendants.select(&:open?) - [dist_task]
          expect { subject }.not_to raise_error
          open_tasks.each do |task|
            expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          end
        end
      end

      context "appeal ready for distribution" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end
        let(:dist_task) { appeal.tasks.active.where(type: DistributionTask.name).first }

        context "with no blocking tasks" do
          it_behaves_like "completed distribution and at JudgeAssign"
        end

        context "with (dispatch) blocking mail task" do
          before do
            # TODO: this _should_ not cancel after we finish
            # https://github.com/department-of-veterans-affairs/caseflow/issues/14057
            # Distribution Blocking. Update this test to properly pass then!
            create(:congressional_interest_mail_task,
                   appeal: appeal,
                   parent: dist_task)
          end
          it_behaves_like "completed distribution and at JudgeAssign"
          it_behaves_like "cancelled distribution children"
        end

        context "with a (distribution) blocking mail task" do
          before do
            create(:extension_request_mail_task,
                   appeal: appeal,
                   parent: dist_task)
          end
          it_behaves_like "completed distribution and at JudgeAssign"
          it_behaves_like "cancelled distribution children"
        end

        context "with a nonblocking mail task" do
          before do
            create(:aod_motion_mail_task,
                   appeal: appeal,
                   parent: appeal.root_task)
          end
          it_behaves_like "completed distribution and at JudgeAssign"
          it "still has the open mail task" do
            aod_mail_task = AodMotionMailTask.where(appeal: appeal).first
            expect(aod_mail_task.open?).to eq(true)
            expect { subject }.not_to raise_error
            expect(aod_mail_task.reload.open?).to eq(true)
          end
        end
      end

      context "appeal at the evidence window state" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.evidence_submission)
        end
        let(:dist_task) { appeal.tasks.open.where(type: DistributionTask.name).first }

        context "with distribution task on_hold" do
          it_behaves_like "completed distribution and at JudgeAssign"
          it_behaves_like "cancelled distribution children"
        end

        context "with the evidence window task as parent" do
          let(:evidence_window_task) { appeal.tasks.open.where(type: EvidenceSubmissionWindowTask.name).first }

          subject do
            BlockedSpecialCaseMovementTask.create!(appeal: appeal,
                                                   assigned_to: cm_user,
                                                   assigned_by: cm_user,
                                                   parent: evidence_window_task)
          end

          it "should error with wrong parent type" do
            expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
          end
        end
      end

      context "appeal at the judge already" do
        let(:appeal) do
          create(:appeal,
                 :assigned_to_judge,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end
        let(:dist_task) { appeal.tasks.where(type: DistributionTask.name).first }

        subject do
          BlockedSpecialCaseMovementTask.create!(appeal: appeal,
                                                 assigned_to: cm_user,
                                                 assigned_by: cm_user,
                                                 parent: dist_task)
        end

        it "should error with appeal not distributable" do
          expect { subject }.to raise_error(Caseflow::Error::IneligibleForBlockedSpecialCaseMovement)
        end
      end
    end

    context "with regular user" do
      let(:user) { create(:user) }
      let(:appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               docket_type: Constants.AMA_DOCKETS.direct_review)
      end
      let(:dist_task) { appeal.tasks.active.where(type: DistributionTask.name).first }

      subject do
        BlockedSpecialCaseMovementTask.create!(appeal: appeal,
                                               assigned_to: user,
                                               assigned_by: user,
                                               parent: dist_task)
      end

      it "should error with user error" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end
  end
end
