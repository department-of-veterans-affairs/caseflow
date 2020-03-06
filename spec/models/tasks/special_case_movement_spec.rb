# frozen_string_literal: true

describe SpecialCaseMovementTask, :postgres do
  describe ".create" do
    context "with Special Case Movement Team user" do
      let(:scm_user) { create(:user) }

      subject do
        SpecialCaseMovementTask.create!(appeal: appeal,
                                        assigned_to: scm_user,
                                        assigned_by: scm_user,
                                        parent: dist_task)
      end

      before do
        SpecialCaseMovementTeam.singleton.add_user(scm_user)
      end

      context "appeal ready for distribution" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end
        let(:dist_task) { appeal.tasks.active.where(type: DistributionTask.name).first }

        context "with no blocking tasks" do
          it "should create the SCM task and JudgeAssign task" do
            expect { subject }.not_to raise_error
            scm_task =  appeal.tasks.where(type: SpecialCaseMovementTask.name).first
            expect(scm_task.status).to eq(Constants.TASK_STATUSES.completed)
            judge_task = appeal.tasks.open.where(type: JudgeAssignTask.name).first
            expect(judge_task.status).to eq(Constants.TASK_STATUSES.assigned)
          end
        end

        context "with blocking mail task" do
          before do
            create(:congressional_interest_mail_task,
                   appeal: appeal,
                   parent: appeal.root_task)
          end
          it "should error with appeal not ready" do
            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Caseflow::Error::IneligibleForSpecialCaseMovement)
            end
          end
        end

        context "with a nonblocking mail task" do
          before do
            create(:aod_motion_mail_task,
                   appeal: appeal,
                   parent: appeal.root_task)
          end
          it "shouldn't error with appeal not ready" do
            expect { subject }.not_to raise_error
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
          it "should error with appeal not ready" do
            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Caseflow::Error::IneligibleForSpecialCaseMovement)
              expect(error.appeal_id).to eq(appeal.id)
            end
          end
        end

        context "with the evidence window task as parent" do
          let(:evidence_window_task) { appeal.tasks.open.where(type: EvidenceSubmissionWindowTask.name).first }

          subject do
            SpecialCaseMovementTask.create!(appeal: appeal,
                                            assigned_to: scm_user,
                                            assigned_by: scm_user,
                                            parent: evidence_window_task)
          end

          it "should error with wrong parent type" do
            expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
          end
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
        SpecialCaseMovementTask.create!(appeal: appeal,
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
